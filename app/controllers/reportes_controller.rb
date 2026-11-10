class ReportesController < ApplicationController
  before_action :require_administrador!

  def tareas_por_mecanico
    resultado = ReporteTareasPorMecanico.call(desde: params[:desde], hasta: params[:hasta])
    return render json: { errors: resultado.errors }, status: :unprocessable_content if resultado.invalid?

    render json: { mecanicos: resultado.filas.map { |fila| serialize_mecanico(fila) } }
  end

  def margen_repuestos
    resultado = ReporteMargenRepuestos.call(desde: params[:desde], hasta: params[:hasta])
    return render json: { errors: resultado.errors }, status: :unprocessable_content if resultado.invalid?

    render json: { margen_total: resultado.margen_total }
  end

  def tareas_frecuentes
    render json: { tareas: ReporteTareasFrecuentes.call.map { |fila| serialize_frecuente(fila) } }
  end

  private

  def serialize_mecanico(fila)
    {
      mecanico: fila.mecanico.as_json(only: %i[id nombre]),
      tomadas: fila.tomadas,
      completadas: fila.completadas
    }
  end

  def serialize_frecuente(fila)
    { descripcion: fila.descripcion, cantidad: fila.cantidad }
  end
end
