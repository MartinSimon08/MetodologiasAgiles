class RepuestosController < ApplicationController
  include Paginable

  before_action :require_administrador!
  before_action :set_orden

  def index
    repuestos, meta = paginar(@orden.repuestos.includes(:registrado_por).order(created_at: :desc, id: :desc))
    render json: {
      repuestos: repuestos.map { |repuesto| serialize(repuesto) },
      meta: meta,
      margen_por_defecto: ConfiguracionTaller.actual.margen_repuestos.to_s("F")
    }
  end

  def create
    repuesto = RepuestoAgregar.call(orden: @orden, registrado_por: current_usuario, **repuesto_params.to_h.symbolize_keys)
    render json: serialize(repuesto), status: :created
  end

  private

  def set_orden
    @orden = Orden.find(params[:orden_id])
  end

  def repuesto_params
    params.require(:repuesto).permit(:repuesto_catalogo_id, :descripcion, :cantidad, :costo_unitario, :margen, :proveedor)
  end

  def serialize(repuesto)
    datos = repuesto.as_json(only: %i[id orden_id repuesto_catalogo_id descripcion cantidad costo_unitario margen precio_cliente proveedor registrado_por_id created_at])
    datos[:ganancia] = (repuesto.precio_cliente - repuesto.costo_unitario * repuesto.cantidad).to_s("F")
    datos[:registrado_por] = repuesto.registrado_por.as_json(only: %i[id nombre])
    datos
  end
end
