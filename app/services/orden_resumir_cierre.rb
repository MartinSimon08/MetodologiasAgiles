class OrdenResumirCierre
  Resumen = Data.define(:orden, :tareas, :repuestos, :mano_de_obra, :total_repuestos, :total, :adelantado,
                        :saldo, :franquicia, :saldo_a_facturar)

  def self.call(orden:)
    tareas = orden.tareas.includes(:mecanico).order(:created_at, :id).to_a
    repuestos = orden.repuestos.vigentes.includes(:ajustes).order(:created_at, :id).to_a
    adelantado = orden.adelantos.sum(:importe).to_d
    total = orden.cerrada? ? orden.total_cerrado : orden.total_a_cobrar

    Resumen.new(
      orden: orden, tareas: tareas, repuestos: repuestos,
      mano_de_obra: orden.mano_de_obra, total_repuestos: orden.total_repuestos,
      total: total, adelantado: adelantado, saldo: total - adelantado,
      franquicia: orden.franquicia, saldo_a_facturar: total - orden.franquicia.to_d
    )
  end
end
