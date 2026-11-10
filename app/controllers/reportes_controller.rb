class ReportesController < ApplicationController
  before_action :require_administrador!

  def tareas_por_mecanico
    resultado = ReporteTareasPorMecanico.call(desde: params[:desde], hasta: params[:hasta])
    return render json: { errors: resultado.errors }, status: :unprocessable_content if resultado.invalid?

    render json: { mecanicos: resultado.filas.map { |fila| serialize(fila) } }
  end

  def margen_repuestos
    resultado = ReporteMargenRepuestos.call(desde: params[:desde], hasta: params[:hasta])
    return render json: { errors: resultado.errors }, status: :unprocessable_content if resultado.invalid?

    render json: { margen_total: resultado.margen_total }
  end

  def ingresos
    resultado = ReporteIngresos.call(desde: params[:desde], hasta: params[:hasta])
    return render json: { errors: resultado.errors }, status: :unprocessable_content if resultado.invalid?

    render json: {
      franquicia_cobrada: resultado.franquicia_cobrada,
      saldo_facturado_aseguradoras: resultado.saldo_facturado_aseguradoras,
      saldo_pendiente_aseguradoras: resultado.saldo_pendiente_aseguradoras,
      ingresos_clientes_directos: resultado.ingresos_clientes_directos,
      total_ingresos: resultado.total_ingresos
    }
  end

  private

  def serialize(fila)
    {
      mecanico: fila.mecanico.as_json(only: %i[id nombre]),
      tomadas: fila.tomadas,
      completadas: fila.completadas
    }
  end
end
