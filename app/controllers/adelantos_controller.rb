class AdelantosController < ApplicationController
  before_action :require_administrador!
  before_action :set_orden

  def index
    render json: { adelantos: serialize_adelantos, saldo: @orden.saldo.to_s }
  end

  def create
    adelanto = nil
    @orden.with_lock do
      adelanto = @orden.adelantos.new(adelanto_params.merge(registrado_por: current_usuario, registrado_en: Time.current))
      adelanto.save!
    end
    render json: serialize_adelanto(adelanto), status: :created
  end

  private

  def set_orden
    @orden = Orden.find(params[:orden_id])
  end

  def adelanto_params
    params.require(:adelanto).permit(:importe)
  end

  def serialize_adelantos
    @orden.adelantos.order(created_at: :desc, id: :desc).map { |adelanto| serialize_adelanto(adelanto) }
  end

  def serialize_adelanto(adelanto)
    adelanto.as_json(only: %i[id orden_id importe registrado_en created_at updated_at])
  end
end
