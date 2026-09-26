class UsuarioResetearPassword
  def self.call(usuario:, password:)
    if password.blank?
      usuario.errors.add(:password, :blank)
      raise ActiveRecord::RecordInvalid, usuario
    end

    usuario.update!(password: password)
    usuario
  end
end
