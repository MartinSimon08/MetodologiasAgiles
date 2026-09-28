class TareaActualizarPrecio
  def self.call(tarea:, precio:)
    tarea.with_lock do
      tarea.update!(precio: precio)
    end

    tarea
  end
end
