class UsuarioDesactivar
  Resultado = Data.define(:usuario, :tareas_liberadas)

  def self.call(usuario:)
    Usuario.transaction do
      administradores = Usuario.administrador.activos.order(:id).lock.to_a
      usuario.lock!
      validar!(usuario, administradores)

      tareas = usuario.tareas.en_curso.order(:id).map { |tarea| TareaLiberar.call(tarea: tarea) }
      usuario.update!(activo: false)

      Resultado.new(usuario: usuario, tareas_liberadas: tareas)
    end
  end

  def self.validar!(usuario, administradores)
    if !usuario.activo?
      usuario.errors.add(:base, :ya_desactivado)
    elsif usuario.administrador? && administradores.none? { |admin| admin.id != usuario.id }
      usuario.errors.add(:base, :ultimo_administrador)
    end

    raise ActiveRecord::RecordInvalid, usuario if usuario.errors.any?
  end
  private_class_method :validar!
end
