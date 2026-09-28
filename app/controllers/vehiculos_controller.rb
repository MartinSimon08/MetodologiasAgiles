class VehiculosController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    vehiculos = Vehiculo.includes(:cliente).order(:patente, :id)
    vehiculos = vehiculos.where(cliente_id: params[:cliente_id]) if params[:cliente_id].present?
    registros, meta = paginar(vehiculos)
    render json: { vehiculos: registros.map { |vehiculo| serialize(vehiculo) }, meta: meta }
  end

  def create
    vehiculo = VehiculoRegistrar.call(**vehiculo_params.to_h.symbolize_keys)
    render json: serialize(vehiculo), status: :created
  end

  def cambiar_duenio
    vehiculo = VehiculoCambiarDuenio.call(vehiculo: Vehiculo.find(params[:id]),
                                          cliente_id: params.require(:vehiculo).require(:cliente_id))
    render json: serialize(vehiculo)
  end

  private

  def vehiculo_params
    params.require(:vehiculo).permit(:cliente_id, :patente, :marca, :modelo, :anio, :kilometraje)
          .with_defaults(patente: nil)
  end

  def serialize(vehiculo)
    vehiculo.as_json(only: %i[id patente marca modelo anio kilometraje created_at])
            .merge(cliente: vehiculo.cliente.as_json(only: %i[id nombre telefono]))
  end
end
