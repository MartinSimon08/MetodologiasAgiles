class Orden < ApplicationRecord
  MOTIVO_MAXIMO = 500

  belongs_to :cliente
  belongs_to :vehiculo
  has_many :tareas, dependent: :restrict_with_error
  has_many :repuestos, dependent: :restrict_with_error
  has_many :adelantos, dependent: :restrict_with_error

  enum :estado, { abierta: "abierta", cerrada: "cerrada", cancelada: "cancelada" }, validate: true

  normalizes :motivo, with: ->(motivo) { motivo.strip }

  validates :motivo, presence: true, length: { maximum: MOTIVO_MAXIMO }
  validates :cancelada_en, presence: true, if: :cancelada?
  validates :cancelada_en, absence: true, unless: :cancelada?
  validates :vehiculo, uniqueness: { conditions: -> { abierta }, message: :con_orden_abierta }, if: :abierta?
  validate :sin_repuestos_pendientes_de_valorizar, if: :cerrada?

  def total
    tareas.sum(:precio).to_d + repuestos.sum(:precio_cliente).to_d
  end

  def saldo
    total - adelantos.sum(:importe).to_d
  end

  private

  def sin_repuestos_pendientes_de_valorizar
    errors.add(:base, :repuestos_pendientes) if repuestos.pendiente_de_valorizar.exists?
  end
end
