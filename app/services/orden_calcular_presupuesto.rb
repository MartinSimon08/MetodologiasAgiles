class OrdenCalcularPresupuesto
  Presupuesto = Data.define(:orden, :tareas, :repuestos, :presupuesto, :total_aseguradora)

  def self.call(orden:)
    unless orden.abierta?
      orden.errors.add(:base, :presupuesto_no_disponible)
      raise ActiveRecord::RecordInvalid, orden
    end

    tareas = orden.tareas.not_cancelada.includes(:mecanico).order(:created_at, :id).to_a
    repuestos = orden.repuestos.vigentes.includes(:ajustes).order(:created_at, :id).to_a

    Presupuesto.new(
      orden: orden,
      tareas: tareas,
      repuestos: repuestos,
      presupuesto: suma_tareas(tareas) + suma_repuestos(repuestos),
      total_aseguradora: orden.total
    )
  end

  def self.suma_tareas(tareas)
    tareas.sum { |tarea| tarea.precio&.to_d || 0 }
  end

  def self.suma_repuestos(repuestos)
    repuestos.sum { |repuesto| repuesto.valorizado? ? repuesto.precio_vigente.to_d : 0 }
  end

  private_class_method :suma_tareas, :suma_repuestos
end
