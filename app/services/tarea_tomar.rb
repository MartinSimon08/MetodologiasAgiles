class TareaTomar
  def self.call(tarea:, mecanico:)
    tarea.with_lock do
      tarea.errors.add(:estado, :no_disponible) unless tarea.pendiente?
      tarea.errors.add(:orden, tarea.orden.estado.to_sym) unless tarea.orden.abierta?
      raise ActiveRecord::RecordInvalid, tarea if tarea.errors.any?

      tarea.update!(estado: :en_curso, mecanico: mecanico, tomada_en: Time.current)
    end

    tarea
  end
end
