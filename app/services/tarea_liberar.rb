class TareaLiberar
  def self.call(tarea:)
    tarea.with_lock do
      unless tarea.en_curso?
        tarea.errors.add(:estado, :no_en_curso)
        raise ActiveRecord::RecordInvalid, tarea
      end

      tarea.update!(estado: :pendiente, mecanico: nil, tomada_en: nil)
    end

    tarea
  end
end
