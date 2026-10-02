class TareasMecanicoController < ApplicationController
  before_action :require_mecanico!

  def index
    tareas = Tarea.joins(:orden).merge(Orden.abierta).includes(orden: %i[cliente vehiculo])

    render json: {
      mias: tareas.en_curso.where(mecanico: current_usuario).order(:tomada_en, :id).map { |tarea| serialize(tarea) },
      disponibles: tareas.pendiente.order(:created_at, :id).map { |tarea| serialize(tarea) }
    }
  end

  private

  def serialize(tarea)
    datos = tarea.as_json(only: %i[id orden_id descripcion estado mecanico_id tomada_en created_at])
    datos[:orden] = {
      id: tarea.orden.id,
      vehiculo: tarea.orden.vehiculo.as_json(only: %i[id patente marca modelo anio]),
      cliente: tarea.orden.cliente.nombre
    }
    datos
  end
end
