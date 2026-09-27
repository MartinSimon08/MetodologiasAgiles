class TareaFrecuenteCrear
  def self.call(descripcion:, precio_sugerido:)
    tarea_frecuente = TareaFrecuente.new(descripcion: descripcion, precio_sugerido: precio_sugerido)
    tarea_frecuente.save!
    tarea_frecuente
  rescue ActiveRecord::RecordNotUnique
    tarea_frecuente.errors.add(:descripcion, :taken)
    raise ActiveRecord::RecordInvalid, tarea_frecuente
  end
end
