class RepuestosCatalogoController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    catalogo = RepuestoCatalogo.order(:nombre, :id)
    if params[:buscar].present?
      termino = ActiveRecord::Base.sanitize_sql_like(params[:buscar].to_s.squish.downcase)
      catalogo = catalogo.where("nombre LIKE ?", "%#{termino}%")
    end
    repuestos, meta = paginar(catalogo)
    render json: { repuestos: repuestos.map { |repuesto| serialize(repuesto) }, meta: meta }
  end

  def create
    repuesto = RepuestoCatalogoGuardar.call(**catalogo_params.to_h.symbolize_keys)
    render json: serialize(repuesto), status: :created
  end

  def update
    repuesto = RepuestoCatalogoGuardar.call(repuesto: RepuestoCatalogo.find(params[:id]), **catalogo_params.to_h.symbolize_keys)
    render json: serialize(repuesto)
  end

  def destroy
    RepuestoCatalogoEliminar.call(repuesto: RepuestoCatalogo.find(params[:id]))
    head :no_content
  end

  private

  def catalogo_params
    params.require(:repuesto_catalogo).permit(:nombre, :precio)
  end

  def serialize(repuesto)
    repuesto.as_json(only: %i[id nombre precio])
  end
end
