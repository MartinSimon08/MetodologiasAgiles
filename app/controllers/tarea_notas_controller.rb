class TareaNotasController < ApplicationController
  before_action :require_mecanico!
  before_action :set_tarea

  def create
    nota = TareaNotaCrear.call(tarea: @tarea, registrado_por: current_usuario, **nota_params.to_h.symbolize_keys)
    render json: serialize(nota), status: :created
  end

  private

  def set_tarea
    @tarea = Tarea.find(params[:tarea_id])
  end

  def nota_params
    params.require(:tarea_nota).permit(:contenido)
  end

  def serialize(nota)
    datos = nota.as_json(only: %i[id tarea_id contenido created_at])
    datos[:registrado_por] = nota.registrado_por.as_json(only: %i[id nombre])
    datos
  end
end
