class JsonWebToken
  ALGORITHM = "HS256".freeze
  EXPIRATION = 12.hours

  def self.encode(payload, exp: EXPIRATION.from_now)
    JWT.encode(payload.merge(exp: exp.to_i), secret, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, secret, true, algorithm: ALGORITHM).first
  rescue JWT::DecodeError
    nil
  end

  def self.secret
    Rails.application.secret_key_base
  end
end
