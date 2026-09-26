class Usuario < ApplicationRecord
  PASSWORD_MIN_LENGTH = 8

  has_secure_password

  enum :rol, { administrador: "administrador", mecanico: "mecanico" }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :nombre, with: ->(nombre) { nombre.strip }

  validates :nombre, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true
end
