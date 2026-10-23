class TareasMecanicoController < ApplicationController
  before_action :require_mecanico!

  def index
    tareas = Tarea.joins(:orden).merge(Orden.abierta)
                  .includes(orden: %i[cliente vehiculo], notas: :registrado_por)

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
    datos[:notas] = tarea.notas.sort_by(&:created_at).map { |nota| serialize_nota(nota) }
    datos
  end

  def serialize_nota(nota)
    datos = nota.as_json(only: %i[id contenido created_at])
    datos[:registrado_por] = nota.registrado_por.as_json(only: %i[id nombre])
    datos
  end
end
