class TareaActualizarPrecio
  def self.call(tarea:, precio:)
    tarea.with_lock do
      tarea.errors.add(:orden, tarea.orden.estado.to_sym) unless tarea.orden.abierta?
      raise ActiveRecord::RecordInvalid, tarea if tarea.errors.any?

      tarea.update!(precio: precio)
    end

    tarea
  end
end
