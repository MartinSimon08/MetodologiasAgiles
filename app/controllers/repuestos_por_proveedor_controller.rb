class RepuestosPorProveedorController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    consulta = RepuestoResumirPorProveedor.call(
      proveedor: params[:proveedor], desde: params[:desde], hasta: params[:hasta]
    )
    if consulta.invalid?
      return render json: { errors: consulta.errors }, status: :unprocessable_content
    end

    repuestos, meta = paginar(consulta.repuestos)
    render json: {
      proveedores: consulta.resumen,
      total_comprado: consulta.total_comprado,
      repuestos: repuestos.map { |repuesto| serialize(repuesto) },
      meta: meta
    }
  end

  private

  def serialize(repuesto)
    datos = repuesto.as_json(only: %i[id descripcion cantidad costo_unitario proveedor created_at orden_id])
    datos[:total_costo] = RepuestoResumirPorProveedor.total_linea(repuesto)
    datos[:orden] = {
      id: repuesto.orden.id,
      cliente: repuesto.orden.cliente.nombre,
      vehiculo: repuesto.orden.vehiculo.as_json(only: %i[id patente marca modelo anio])
    }
    datos
  end
end
