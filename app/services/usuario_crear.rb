class UsuarioCrear
  def self.call(nombre:, email:, rol:, password:)
    Usuario.create!(nombre: nombre, email: email, rol: rol, password: password)
  end
end
