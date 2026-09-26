class TareaCrear
  def self.call(orden:, descripcion:)
    orden.tareas.create!(descripcion: descripcion)
  end
end
