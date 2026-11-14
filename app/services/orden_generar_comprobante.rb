class OrdenGenerarComprobante
  Comprobante = Data.define(:orden, :tareas, :repuestos, :mano_de_obra, :total_repuestos, :total, :adelantado, :saldo)

  def self.call(orden:)
    unless orden.cerrada?
      orden.errors.add(:base, :comprobante_no_disponible)
      raise ActiveRecord::RecordInvalid, orden
    end

    tareas = orden.tareas.terminada.where.not(aprobacion: :rechazada)
      .includes(:mecanico).order(:created_at, :id).to_a
    repuestos = orden.repuestos.vigentes.where.not(aprobacion: :rechazado)
      .includes(:ajustes).order(:created_at, :id).to_a
    adelantado = orden.adelantos.sum(:importe).to_d
    total = orden.total_cerrado

    Comprobante.new(
      orden: orden, tareas: tareas, repuestos: repuestos,
      mano_de_obra: orden.mano_de_obra, total_repuestos: orden.total_repuestos,
      total: total, adelantado: adelantado, saldo: total - adelantado
    )
  end
end
