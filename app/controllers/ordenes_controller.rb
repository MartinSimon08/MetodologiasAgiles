class OrdenesController < ApplicationController
  include Paginable

  before_action :require_administrador!, only: :create

  def index
    ordenes, meta = paginar(Orden.includes(:cliente, :vehiculo).order(created_at: :desc, id: :desc))
    render json: { ordenes: ordenes.map { |orden| serialize(orden) }, meta: meta }
  end

  def show
    render json: serialize(Orden.find(params[:id]))
  end

  def create
    orden = OrdenAbrir.call(**orden_params.to_h.symbolize_keys)
    render json: serialize(orden), status: :created
  end

  private

  def orden_params
    params.require(:orden).permit(:vehiculo_id, :motivo).with_defaults(vehiculo_id: nil, motivo: nil)
  end

  def serialize(orden)
    datos = orden.as_json(only: %i[id motivo estado created_at])
    datos[:cliente] = orden.cliente.as_json(only: %i[id nombre telefono email])
    datos[:vehiculo] = orden.vehiculo.as_json(only: %i[id patente marca modelo anio])
    datos
  end
end
