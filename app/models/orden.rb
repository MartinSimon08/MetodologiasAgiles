class Orden < ApplicationRecord
  MOTIVO_MAXIMO = 500

  belongs_to :cliente
  belongs_to :vehiculo
  belongs_to :cerrada_por, class_name: "Usuario", optional: true
  has_many :tareas, dependent: :restrict_with_error
  has_many :repuestos, dependent: :restrict_with_error
  has_many :adelantos, dependent: :restrict_with_error

  enum :estado, { abierta: "abierta", cerrada: "cerrada", cancelada: "cancelada" }, validate: true

  normalizes :motivo, with: ->(motivo) { motivo.strip }

  validates :motivo, presence: true, length: { maximum: MOTIVO_MAXIMO }
  validates :cancelada_en, presence: true, if: :cancelada?
  validates :cancelada_en, absence: true, unless: :cancelada?
  validates :cerrada_en, :cerrada_por, :total_cerrado, presence: true, if: :cerrada?
  validates :cerrada_en, :cerrada_por, :total_cerrado, absence: true, unless: :cerrada?
  validates :vehiculo, uniqueness: { conditions: -> { abierta }, message: :con_orden_abierta }, if: :abierta?
  validate :sin_repuestos_pendientes_de_valorizar, if: :cerrada?

  def total
    return total_cerrado if cerrada?

    mano_de_obra_cargada + total_repuestos
  end

  def mano_de_obra_cargada
    tareas.not_cancelada.sum(:precio).to_d
  end

  def mano_de_obra
    tareas.terminada.sum(:precio).to_d
  end

  def total_repuestos
    repuestos.valorizado.sum(:precio_cliente).to_d
  end

  def total_a_cobrar
    mano_de_obra + total_repuestos
  end

  def saldo
    total - adelantos.sum(:importe).to_d
  end

  private

  def sin_repuestos_pendientes_de_valorizar
    errors.add(:base, :repuestos_pendientes) if repuestos.pendiente_de_valorizar.exists?
  end
end
