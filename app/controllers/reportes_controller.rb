class ReportesController < ApplicationController
  before_action :require_administrador!

  def tareas_frecuentes
    render json: { tareas: ReporteTareasFrecuentes.call.map { |fila| serialize(fila) } }
  end

  private

  def serialize(fila)
    { descripcion: fila.descripcion, cantidad: fila.cantidad }
  end
end
