class CasoAvisarListoParaRetirar
  def self.call(orden:)
    return unless orden.abierta?

    tareas = orden.tareas
    return if tareas.none? || tareas.where.not(estado: :terminada).exists?

    caso = orden.caso
    return unless caso

    ActionCable.server.broadcast(RecepcionChannel::STREAM, {
      tipo: "caso_listo_para_retirar",
      caso_id: caso.id,
      numero_siniestro: caso.numero_siniestro,
      orden_id: orden.id,
      vehiculo: orden.vehiculo.as_json(only: %i[id patente marca modelo anio]),
      aseguradora: caso.aseguradora.as_json(only: %i[id nombre])
    })
  end
end
