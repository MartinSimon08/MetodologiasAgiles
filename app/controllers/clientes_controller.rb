class ClientesController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    clientes, meta = paginar(filtrar_por_tipo(ClienteBuscar.call(params[:q])))
    asegurados = Caso.where(asegurado_id: clientes.map(&:id)).distinct.pluck(:asegurado_id).to_set
    render json: { clientes: clientes.map { |cliente| serialize(cliente, asegurados.include?(cliente.id)) }, meta: meta }
  end

  def show
    cliente = Cliente.find(params[:id])
    render json: serialize(cliente, cliente.casos.exists?).merge(
      vehiculos: cliente.vehiculos.order(:patente).as_json(only: %i[id patente marca modelo anio]),
      casos: cliente.casos.includes(:aseguradora, :vehiculo).order(created_at: :desc, id: :desc).map { |caso| serialize_caso(caso) },
      ordenes: Orden.where(cliente_id: cliente.id).includes(:vehiculo).order(created_at: :desc, id: :desc).limit(50).map do |orden|
        orden.as_json(only: %i[id estado motivo created_at]).merge(vehiculo: orden.vehiculo.as_json(only: %i[id patente marca modelo]))
      end
    )
  end

  def create
    cliente = ClienteRegistrar.call(**cliente_params.to_h.symbolize_keys)
    render json: serialize(cliente), status: :created
  end

  def update
    cliente = Cliente.find(params[:id])
    cliente.update!(params.require(:cliente).permit(:nombre, :telefono, :email))
    render json: serialize(cliente, cliente.casos.exists?)
  end

  private

  def cliente_params
    params.require(:cliente).permit(:nombre, :telefono, :email).with_defaults(nombre: nil, telefono: nil)
  end

  def filtrar_por_tipo(clientes)
    con_casos = Caso.select(:asegurado_id)
    case params[:tipo]
    when "asegurado" then clientes.where(id: con_casos)
    when "particular" then clientes.where.not(id: con_casos)
    else clientes
    end
  end

  def serialize(cliente, asegurado = false)
    cliente.as_json(only: %i[id nombre telefono email created_at]).merge("asegurado" => asegurado,
                                                                        "telegram_vinculada" => cliente.telegram_vinculada?)
  end

  def serialize_caso(caso)
    caso.as_json(only: %i[id numero_siniestro fecha_turno orden_id]).merge(
      aseguradora: caso.aseguradora.as_json(only: %i[id nombre]),
      vehiculo: caso.vehiculo.as_json(only: %i[id patente marca modelo])
    )
  end
end
