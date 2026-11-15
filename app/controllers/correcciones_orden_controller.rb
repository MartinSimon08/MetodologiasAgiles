class CorreccionesOrdenController < ApplicationController
  before_action :require_administrador!

  def index
    orden = Orden.find(params[:orden_id])
    correcciones = orden.correcciones.includes(:usuario).order(created_at: :desc, id: :desc)
    render json: { correcciones: correcciones.map { |correccion| serialize(correccion) } }
  end

  private

  def serialize(correccion)
    correccion.as_json(only: %i[id campo motivo revision_confirmada created_at]).merge(
      "valor_anterior" => correccion.valor_anterior&.to_s("F"),
      "valor_nuevo" => correccion.valor_nuevo&.to_s("F"),
      "usuario" => correccion.usuario.as_json(only: %i[id nombre])
    )
  end
end
