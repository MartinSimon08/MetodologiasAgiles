class Usuario < ApplicationRecord
  PASSWORD_MIN_LENGTH = 8

  has_secure_password

  has_many :tareas, foreign_key: :mecanico_id, inverse_of: :mecanico, dependent: :restrict_with_error
  has_many :repuestos_registrados, class_name: "Repuesto", foreign_key: :registrado_por_id,
                                   inverse_of: :registrado_por, dependent: :restrict_with_error

  enum :rol, { administrador: "administrador", mecanico: "mecanico" }, validate: true

  scope :activos, -> { where(activo: true) }

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :nombre, with: ->(nombre) { nombre.strip }

  validates :nombre, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true
end
