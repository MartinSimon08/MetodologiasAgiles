class TareaCrear
  def self.call(orden:, descripcion:, precio: nil)
    tarea = orden.tareas.create!(descripcion: descripcion, precio: precio)
    notificar(tarea)
    tarea
  end

  def self.notificar(tarea)
    ActionCable.server.broadcast(TareasChannel::STREAM, {
      id: tarea.id,
      descripcion: tarea.descripcion,
      orden_id: tarea.orden.id,
      cliente: tarea.orden.cliente.nombre,
      vehiculo: tarea.orden.vehiculo.as_json(only: %i[id patente marca modelo anio])
    })
  end
end
