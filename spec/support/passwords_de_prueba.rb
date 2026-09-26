module PasswordsDePrueba
  VALIDA = SecureRandom.alphanumeric(16)
  INICIAL = SecureRandom.alphanumeric(16)
  NUEVA = SecureRandom.alphanumeric(16)
  ANTERIOR = SecureRandom.alphanumeric(16)
  INCORRECTA = SecureRandom.alphanumeric(16)
  CORTA = SecureRandom.alphanumeric(Usuario::PASSWORD_MIN_LENGTH - 1)
end
