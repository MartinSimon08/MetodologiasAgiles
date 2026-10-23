class TareaNotaCrear
  def self.call(tarea:, registrado_por:, contenido:)
    nota = tarea.notas.build(registrado_por: registrado_por, contenido: contenido)
    nota.errors.add(:orden, tarea.orden.estado.to_sym) unless tarea.orden.abierta?
    raise ActiveRecord::RecordInvalid, nota if nota.errors.any?

    nota.save!
    nota
  end
end
