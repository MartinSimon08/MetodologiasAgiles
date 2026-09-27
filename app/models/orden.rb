class Orden < ApplicationRecord
  belongs_to :cliente
  has_many :tareas, dependent: :restrict_with_error

  enum :estado, { abierta: "abierta", cerrada: "cerrada" }, validate: true

  validates :vehiculo, presence: true
end
