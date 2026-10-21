class OrdenCalcularTotalParcial
  TotalParcial = Data.define(:orden, :tareas, :repuestos, :mano_de_obra, :total_repuestos, :total, :a_cobrar_hoy)

  def self.call(orden:)
    unless orden.abierta?
      orden.errors.add(:base, :total_parcial_no_disponible)
      raise ActiveRecord::RecordInvalid, orden
    end

    TotalParcial.new(
      orden: orden,
      tareas: orden.tareas.not_cancelada.includes(:mecanico).order(:created_at, :id).to_a,
      repuestos: orden.repuestos.order(:created_at, :id).to_a,
      mano_de_obra: orden.mano_de_obra_cargada,
      total_repuestos: orden.total_repuestos,
      total: orden.total,
      a_cobrar_hoy: orden.total_a_cobrar
    )
  end
end
