class JsonWebToken
  ALGORITHM = "HS256".freeze
  INACTIVIDAD_MAXIMA = 30.minutes

  def self.encode(payload, exp: INACTIVIDAD_MAXIMA.from_now)
    JWT.encode(payload.merge(exp: exp.to_i), secret, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, secret, true, algorithm: ALGORITHM).first
  rescue JWT::DecodeError
    nil
  end

  def self.para(usuario)
    encode({ usuario_id: usuario.id, rol: usuario.rol })
  end

  def self.secret
    Rails.application.secret_key_base
  end
end
