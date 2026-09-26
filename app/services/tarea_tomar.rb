class TareaTomar
  def self.call(tarea:, mecanico:)
    tarea.with_lock do
      unless tarea.pendiente?
        tarea.errors.add(:estado, :no_disponible)
        raise ActiveRecord::RecordInvalid, tarea
      end

      tarea.update!(estado: :en_curso, mecanico: mecanico, tomada_en: Time.current)
    end

    tarea
  end
end
