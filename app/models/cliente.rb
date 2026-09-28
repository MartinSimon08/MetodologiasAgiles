class Cliente < ApplicationRecord
  TELEFONO_FORMATO = /\A\+?\d{6,15}\z/

  has_many :vehiculos, dependent: :restrict_with_error

  normalizes :nombre, with: ->(nombre) { nombre.strip }
  normalizes :telefono, with: ->(telefono) { telefono.gsub(/[\s\-().]/, "") }
  normalizes :email, with: ->(email) { email.strip.downcase.presence }

  validates :nombre, presence: true
  validates :telefono, presence: true,
                       uniqueness: true,
                       format: { with: TELEFONO_FORMATO, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
end
