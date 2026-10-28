class AseguradorasController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    aseguradoras = Aseguradora.order(:nombre, :id)
    aseguradoras = aseguradoras.activas if params[:solo_activas] == "true"
    if params[:buscar].present?
      termino = ActiveRecord::Base.sanitize_sql_like(params[:buscar].to_s.squish)
      aseguradoras = aseguradoras.where("nombre ILIKE ?", "%#{termino}%")
    end
    pagina, meta = paginar(aseguradoras)
    render json: { aseguradoras: pagina.map { |aseguradora| serialize(aseguradora) }, meta: meta }
  end

  def create
    aseguradora = AseguradoraGuardar.call(**aseguradora_params.to_h.symbolize_keys)
    render json: serialize(aseguradora), status: :created
  end

  def update
    aseguradora = AseguradoraGuardar.call(aseguradora: Aseguradora.find(params[:id]), **aseguradora_params.to_h.symbolize_keys)
    render json: serialize(aseguradora)
  end

  def destroy
    AseguradoraEliminar.call(aseguradora: Aseguradora.find(params[:id]))
    head :no_content
  end

  def desactivar
    render json: serialize(AseguradoraCambiarEstado.call(aseguradora: Aseguradora.find(params[:id]), activa: false))
  end

  def activar
    render json: serialize(AseguradoraCambiarEstado.call(aseguradora: Aseguradora.find(params[:id]), activa: true))
  end

  private

  def aseguradora_params
    params.require(:aseguradora).permit(:nombre, :telefono, :email)
  end

  def serialize(aseguradora)
    aseguradora.as_json(only: %i[id nombre telefono email activa created_at])
  end
end
