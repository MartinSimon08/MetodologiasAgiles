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
    render json: { repuestos: repuestos.as_json(only: %i[id nombre ultimo_costo]), meta: meta }
  end
end
