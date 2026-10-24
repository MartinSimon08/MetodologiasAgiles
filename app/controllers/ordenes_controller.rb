class OrdenesController < ApplicationController
  include Paginable

  before_action :require_administrador!, only: %i[create cancelar cerrar resumen_cierre total_parcial]

  def index
    ordenes = Orden.includes(:cliente, :vehiculo, :cerrada_por).order(created_at: :desc, id: :desc)
    ordenes = ordenes.where(estado: params[:estado]) if Orden.estados.key?(params[:estado])
    ordenes, meta = paginar(ordenes)
    render json: { ordenes: ordenes.map { |orden| serialize(orden) }, meta: meta }
  end

  def show
    render json: serialize(Orden.includes(:cerrada_por).find(params[:id]))
  end

  def create
    orden = OrdenAbrir.call(**orden_params.to_h.symbolize_keys)
    render json: serialize(orden), status: :created
  end

  def cancelar
    resultado = OrdenCancelar.call(orden: Orden.find(params[:id]))
    render json: serialize(resultado.orden).merge(
      tareas_liberadas: resultado.tareas_liberadas.map { |tarea| tarea.as_json(only: %i[id descripcion]) }
    )
  end

  def cerrar
    orden = OrdenCerrar.call(
      orden: Orden.find(params[:id]), cerrada_por: current_usuario,
      descartar_pendientes: ActiveModel::Type::Boolean.new.cast(params[:descartar_pendientes]) == true
    )
    render json: serialize(orden)
  end

  def resumen_cierre
    render json: serialize_resumen(OrdenResumirCierre.call(orden: Orden.find(params[:id])))
  end

  def total_parcial
    render json: serialize_total_parcial(OrdenCalcularTotalParcial.call(orden: Orden.find(params[:id])))
  end

  private

  def orden_params
    params.require(:orden).permit(:vehiculo_id, :motivo).with_defaults(vehiculo_id: nil, motivo: nil)
  end

  def serialize(orden)
    datos = orden.as_json(only: %i[id motivo estado created_at cancelada_en cerrada_en])
    datos[:cliente] = orden.cliente.as_json(only: %i[id nombre telefono email])
    datos[:vehiculo] = orden.vehiculo.as_json(only: %i[id patente marca modelo anio])
    datos[:cerrada_por] = orden.cerrada_por&.as_json(only: %i[id nombre])
    datos[:total_cerrado] = orden.total_cerrado&.to_s("F") if current_usuario.administrador?
    datos
  end

  def serialize_resumen(resumen)
    {
      orden_id: resumen.orden.id,
      estado: resumen.orden.estado,
      tareas: resumen.tareas.map { |tarea| serialize_linea_tarea(tarea) },
      repuestos: resumen.repuestos.map do |repuesto|
        repuesto.as_json(only: %i[id descripcion cantidad estado]).merge("precio_cliente" => repuesto.precio_cliente&.to_s("F"))
      end,
      mano_de_obra: resumen.mano_de_obra.to_s("F"),
      total_repuestos: resumen.total_repuestos.to_s("F"),
      total: resumen.total.to_s("F"),
      adelantado: resumen.adelantado.to_s("F"),
      saldo: resumen.saldo.to_s("F")
    }
  end

  def serialize_total_parcial(parcial)
    {
      orden_id: parcial.orden.id,
      tareas: parcial.tareas.map { |tarea| serialize_linea_tarea(tarea) },
      repuestos: parcial.repuestos.map do |repuesto|
        repuesto.as_json(only: %i[id descripcion cantidad estado]).merge(
          "costo_unitario" => repuesto.costo_unitario&.to_s("F"), "margen" => repuesto.margen&.to_s("F"),
          "precio_cliente" => repuesto.precio_cliente&.to_s("F")
        )
      end,
      mano_de_obra: parcial.mano_de_obra.to_s("F"),
      total_repuestos: parcial.total_repuestos.to_s("F"),
      total: parcial.total.to_s("F"),
      a_cobrar_hoy: parcial.a_cobrar_hoy.to_s("F")
    }
  end

  def serialize_linea_tarea(tarea)
    tarea.as_json(only: %i[id descripcion estado terminada_en]).merge(
      "precio" => tarea.precio&.to_s("F"), "mecanico" => tarea.mecanico&.as_json(only: %i[id nombre])
    )
  end
end
