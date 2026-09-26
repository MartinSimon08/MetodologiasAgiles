class UsuarioAutenticar
  def self.call(email:, password:)
    usuario = Usuario.find_by(email: email.to_s.strip.downcase)
    return unless usuario&.authenticate(password.to_s)

    JsonWebToken.encode({ usuario_id: usuario.id, rol: usuario.rol })
  end
end
