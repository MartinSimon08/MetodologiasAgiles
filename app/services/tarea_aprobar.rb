class TareaAprobar
  def self.call(tarea:)
    tarea.with_lock do
      tarea.errors.add(:orden, tarea.orden.estado.to_sym) unless tarea.orden.abierta?
      raise ActiveRecord::RecordInvalid, tarea if tarea.errors.any?

      tarea.update!(aprobacion: :aprobada)
    end

    tarea
  end
end
