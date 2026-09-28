class TareasController < ApplicationController
  include Paginable

  before_action :require_administrador!, only: :create
  before_action :require_mecanico!, only: %i[tomar completar liberar]
  before_action :set_orden, only: %i[index create]
  before_action :set_tarea, only: %i[tomar completar liberar]
  before_action :require_responsable!, only: %i[completar liberar]

  def index
    tareas, meta = paginar(@orden.tareas.order(:created_at, :id))
    render json: { tareas: tareas.map { |tarea| serialize(tarea) }, meta: meta }
  end

  def create
    tarea = TareaCrear.call(orden: @orden, **tarea_params.to_h.symbolize_keys)
    render json: serialize(tarea), status: :created
  end

  def tomar
    tarea = TareaTomar.call(tarea: @tarea, mecanico: current_usuario)
    render json: serialize(tarea)
  end

  def completar
    tarea = TareaCompletar.call(tarea: @tarea)
    render json: serialize(tarea)
  end

  def liberar
    tarea = TareaLiberar.call(tarea: @tarea)
    render json: serialize(tarea)
  end

  private

  def set_orden
    @orden = Orden.find(params[:orden_id])
  end

  def set_tarea
    @tarea = Tarea.find(params[:id])
  end

  def require_responsable!
    head :forbidden unless @tarea.mecanico_id == current_usuario.id
  end

  def tarea_params
    params.require(:tarea).permit(:descripcion, :precio).with_defaults(descripcion: nil)
  end

  def serialize(tarea)
    datos = tarea.as_json(only: %i[id orden_id descripcion estado mecanico_id tomada_en terminada_en created_at])
    datos["precio"] = tarea.precio&.to_f
    datos[:mecanico] = tarea.mecanico&.as_json(only: %i[id nombre])
    datos
  end
end
