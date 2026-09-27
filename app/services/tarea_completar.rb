class TareaCompletar
  def self.call(tarea:)
    tarea.with_lock do
      unless tarea.en_curso?
        tarea.errors.add(:estado, :no_en_curso)
        raise ActiveRecord::RecordInvalid, tarea
      end

      tarea.update!(estado: :terminada, terminada_en: Time.current)
    end

    tarea
  end
end
