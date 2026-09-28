class UsuarioAutenticar
  def self.call(email:, password:)
    usuario = Usuario.authenticate_by(email: email.to_s, password: password.to_s)
    return unless usuario

    JsonWebToken.para(usuario)
  end
end
