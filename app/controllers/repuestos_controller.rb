class RepuestosController < ApplicationController
  include Paginable

  before_action :require_administrador!, only: %i[index valorizar vista_previa update destroy]
  before_action :set_orden, only: %i[index create valorizar vista_previa update destroy]
  before_action :set_repuesto, only: %i[valorizar update destroy]

  def index
    repuestos, meta = paginar(@orden.repuestos.vigentes.includes(:registrado_por).order(created_at: :desc, id: :desc))
    quitados = @orden.repuestos.quitados.includes(:registrado_por, :quitado_por).order(quitado_en: :desc, id: :desc)
    render json: {
      repuestos: repuestos.map { |repuesto| serialize(repuesto) },
      meta: meta,
      quitados: quitados.map { |repuesto| serialize(repuesto) }
    }
  end

  def create
    repuesto = if current_usuario.administrador?
      RepuestoAgregar.call(orden: @orden, registrado_por: current_usuario, **repuesto_params.to_h.symbolize_keys)
    else
      RepuestoAvisar.call(orden: @orden, registrado_por: current_usuario, **aviso_params.to_h.symbolize_keys)
    end
    render json: serialize(repuesto), status: :created
  end

  def update
    repuesto = RepuestoEditar.call(repuesto: @repuesto, atributos: editar_params.to_h.symbolize_keys)
    render json: serialize(repuesto)
  end

  def destroy
    repuesto = RepuestoQuitar.call(repuesto: @repuesto, quitado_por: current_usuario)
    render json: serialize(repuesto)
  end

  def valorizar
    repuesto = RepuestoValorizar.call(repuesto: @repuesto, **valorizar_params.to_h.symbolize_keys)
    render json: serialize(repuesto)
  end

  def vista_previa
    repuesto = RepuestoAgregar.vista_previa(orden: @orden, registrado_por: current_usuario, **repuesto_params.to_h.symbolize_keys)
    render json: {
      precio_cliente: repuesto.precio_cliente.to_s("F"),
      ganancia: ganancia(repuesto),
      margen: repuesto.margen.to_s("F")
    }
  end

  private

  def set_orden
    @orden = Orden.find(params[:orden_id])
  end

  def set_repuesto
    @repuesto = @orden.repuestos.find(params[:id])
  end

  def repuesto_params
    params.require(:repuesto).permit(:repuesto_catalogo_id, :descripcion, :cantidad, :costo_unitario, :margen, :proveedor)
  end

  def aviso_params
    params.require(:repuesto).permit(:descripcion, :cantidad).with_defaults(descripcion: nil, cantidad: nil)
  end

  def valorizar_params
    params.require(:repuesto).permit(:costo_unitario, :margen).with_defaults(costo_unitario: nil)
  end

  def editar_params
    params.require(:repuesto).permit(:cantidad, :costo_unitario, :margen, :proveedor)
  end

  def serialize(repuesto)
    datos = repuesto.as_json(only: %i[
      id orden_id repuesto_catalogo_id descripcion cantidad costo_unitario margen precio_cliente
      proveedor registrado_por_id estado created_at quitado_en
    ])
    datos[:ganancia] = repuesto.valorizado? ? ganancia(repuesto) : nil
    datos[:registrado_por] = repuesto.registrado_por.as_json(only: %i[id nombre])
    datos[:quitado_por] = repuesto.quitado_por&.as_json(only: %i[id nombre])
    datos
  end

  def ganancia(repuesto)
    (repuesto.precio_cliente - repuesto.costo_unitario * repuesto.cantidad).to_s("F")
  end
end
