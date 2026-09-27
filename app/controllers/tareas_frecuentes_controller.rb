class TareasFrecuentesController < ApplicationController
  include Paginable

  before_action :require_administrador!, only: :create

  def index
    tareas_frecuentes, meta = paginar(TareaFrecuente.order(:descripcion, :id))
    render json: { tareas_frecuentes: tareas_frecuentes.map { |tarea_frecuente| serialize(tarea_frecuente) }, meta: meta }
  end

  def create
    tarea_frecuente = TareaFrecuenteCrear.call(**tarea_frecuente_params.to_h.symbolize_keys)
    render json: serialize(tarea_frecuente), status: :created
  end

  private

  def tarea_frecuente_params
    params.require(:tarea_frecuente).permit(:descripcion, :precio_sugerido).with_defaults(descripcion: nil, precio_sugerido: nil)
  end

  def serialize(tarea_frecuente)
    tarea_frecuente.as_json(only: %i[id descripcion precio_sugerido created_at])
  end
end
