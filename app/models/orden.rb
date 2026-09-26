class Orden < ApplicationRecord
  has_many :tareas, dependent: :restrict_with_error

  enum :estado, { abierta: "abierta", cerrada: "cerrada" }, validate: true

  validates :cliente, presence: true
  validates :vehiculo, presence: true
end
