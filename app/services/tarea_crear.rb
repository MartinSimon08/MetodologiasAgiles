class TareaCrear
  def self.call(orden:, descripcion:, precio: nil)
    orden.tareas.create!(descripcion: descripcion, precio: precio)
  end
end
