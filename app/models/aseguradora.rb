class Aseguradora < ApplicationRecord
  TELEFONO_FORMATO = /\A\+?\d{6,15}\z/

  scope :activas, -> { where(activa: true) }

  normalizes :nombre, with: ->(nombre) { nombre.squish }
  normalizes :telefono, with: ->(telefono) { telefono.gsub(/[\s\-().]/, "").presence }
  normalizes :email, with: ->(email) { email.strip.downcase.presence }

  validates :nombre, presence: true, length: { maximum: 200 }, uniqueness: { case_sensitive: false }
  validates :telefono, format: { with: TELEFONO_FORMATO }, allow_nil: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
end
