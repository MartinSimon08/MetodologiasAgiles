class VehiculoHistorial
  Entrada = Data.define(:orden, :tareas, :mecanicos, :repuestos)

  def self.call(vehiculo:)
    Orden.cerrada.where(vehiculo: vehiculo)
         .includes(:cliente, :cerrada_por, tareas: :mecanico, repuestos: :ajustes)
         .order(cerrada_en: :desc, id: :desc)
  end

  def self.detallar(orden)
    tareas = orden.tareas.select { |tarea| tarea.terminada? && !tarea.aprobacion_rechazada? }
                  .sort_by { |tarea| [ tarea.created_at, tarea.id ] }
    repuestos = orden.repuestos.select { |repuesto| repuesto.quitado_en.nil? && !repuesto.aprobacion_rechazado? }
                         .sort_by { |repuesto| [ repuesto.created_at, repuesto.id ] }

    Entrada.new(orden: orden, tareas: tareas, mecanicos: tareas.filter_map(&:mecanico).uniq, repuestos: repuestos)
  end
end
