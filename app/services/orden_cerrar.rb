class OrdenCerrar
  def self.call(orden:, cerrada_por:, descartar_pendientes: false)
    orden.with_lock do
      unless orden.abierta?
        orden.errors.add(:base, orden.cerrada? ? :ya_cerrada : :cancelada_no_cerrable)
        raise ActiveRecord::RecordInvalid, orden
      end

      tareas = orden.tareas.order(:id).lock.to_a
      pendientes = tareas.select(&:pendiente?)
      orden.errors.add(:base, :tareas_en_curso) if tareas.any?(&:en_curso?)
      orden.errors.add(:base, :tareas_pendientes) if pendientes.any? && !descartar_pendientes
      pendientes_de_valorizar = orden.repuestos.vigentes.where.not(aprobacion: :rechazado).pendiente_de_valorizar
      orden.errors.add(:base, :repuestos_pendientes) if pendientes_de_valorizar.exists?
      raise ActiveRecord::RecordInvalid, orden if orden.errors.any?

      pendientes.each { |tarea| tarea.update!(estado: :cancelada) }
      orden.update!(estado: :cerrada, cerrada_en: Time.current, cerrada_por: cerrada_por,
                    total_cerrado: orden.total_a_cobrar)
      orden
    end
  end
end
