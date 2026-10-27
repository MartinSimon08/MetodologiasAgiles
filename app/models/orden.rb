class Orden < ApplicationRecord
  MOTIVO_MAXIMO = 500

  belongs_to :cliente
  belongs_to :vehiculo
  belongs_to :cerrada_por, class_name: "Usuario", optional: true
  has_many :tareas, dependent: :restrict_with_error
  has_many :repuestos, dependent: :restrict_with_error
  has_many :adelantos, dependent: :restrict_with_error
  has_many :ajustes_repuesto, through: :repuestos, source: :ajustes

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
    tareas.not_cancelada.where.not(aprobacion: :rechazada).sum(:precio).to_d
  end

  def mano_de_obra
    tareas.terminada.where.not(aprobacion: :rechazada).sum(:precio).to_d
  end

  def total_repuestos
    repuestos_que_suman.valorizado.sum(:precio_cliente).to_d + total_ajustes_repuestos
  end

  def total_a_cobrar
    mano_de_obra + total_repuestos
  end

  def saldo
    total - adelantos.sum(:importe).to_d
  end

  def total_reemplazando(repuesto, precio:, incluir_ajustes_del_repuesto: true)
    vigentes = repuestos_que_suman
    vigentes = vigentes.where.not(id: repuesto.id) unless incluir_ajustes_del_repuesto
    mano_de_obra_cargada +
      repuestos_que_suman.where.not(id: repuesto.id).sum(:precio_cliente).to_d +
      (repuesto.aprobacion_rechazado? ? 0 : precio.to_d) +
      AjusteRepuesto.where(repuesto_id: vigentes.select(:id)).sum(:ajuste_precio_cliente).to_d
  end

  def alcanza_para_adelantos?(repuesto, precio:, incluir_ajustes_del_repuesto: true)
    total_reemplazando(
      repuesto, precio: precio, incluir_ajustes_del_repuesto: incluir_ajustes_del_repuesto
    ) >= adelantos.sum(:importe).to_d
  end

  private

  def repuestos_que_suman
    repuestos.vigentes.where.not(aprobacion: :rechazado)
  end

  def total_ajustes_repuestos
    AjusteRepuesto.where(repuesto_id: repuestos_que_suman.select(:id)).sum(:ajuste_precio_cliente).to_d
  end

  def sin_repuestos_pendientes_de_valorizar
    pendientes = repuestos.vigentes.where.not(aprobacion: :rechazado).pendiente_de_valorizar
    errors.add(:base, :repuestos_pendientes) if pendientes.exists?
  end
end
