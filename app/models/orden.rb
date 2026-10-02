class Orden < ApplicationRecord
  MOTIVO_MAXIMO = 500

  belongs_to :cliente
  belongs_to :vehiculo
  has_many :tareas, dependent: :restrict_with_error
  has_many :repuestos, dependent: :restrict_with_error

  enum :estado, { abierta: "abierta", cerrada: "cerrada" }, validate: true

  normalizes :motivo, with: ->(motivo) { motivo.strip }

  validates :motivo, presence: true, length: { maximum: MOTIVO_MAXIMO }
end
