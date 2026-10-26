class Repuesto < ApplicationRecord
  belongs_to :orden
  belongs_to :repuesto_catalogo, optional: true
  belongs_to :registrado_por, class_name: "Usuario"
  belongs_to :quitado_por, class_name: "Usuario", optional: true, inverse_of: :repuestos_quitados
  has_one_attached :comprobante
  has_many :ajustes, class_name: "AjusteRepuesto", dependent: :restrict_with_error, inverse_of: :repuesto

  enum :estado, { pendiente_de_valorizar: "pendiente_de_valorizar", valorizado: "valorizado" },
    validate: true, default: :valorizado
  enum :aprobacion, { pendiente: "pendiente", aprobado: "aprobado", rechazado: "rechazado" },
    prefix: true, validate: true, default: :pendiente

  scope :vigentes, -> { where(quitado_en: nil) }
  scope :quitados, -> { where.not(quitado_en: nil) }

  normalizes :descripcion, with: ->(descripcion) { descripcion.squish }

  validates :descripcion, presence: true, length: { maximum: 200 }
  validates :cantidad, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 2_147_483_647 }
  validates :costo_unitario, numericality: { greater_than_or_equal_to: 0, less_than: 10_000_000_000 }, allow_nil: true
  validates :margen, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :costo_unitario, :margen, presence: true, if: :valorizado?
  validates :quitado_en, presence: true, if: :quitado_por_id?
  validates :quitado_por, presence: true, if: :quitado_en?

  def precio_vigente
    return unless valorizado? && precio_cliente

    precio_cliente + suma_de_ajustes(:ajuste_precio_cliente)
  end

  def costo_vigente
    return unless valorizado? && costo_unitario

    costo_unitario * cantidad + suma_de_ajustes(:ajuste_costo)
  end

  def cantidad_disponible
    cantidad - suma_de_cantidades
  end

  private

  def suma_de_ajustes(columna)
    if ajustes.loaded?
      ajustes.sum { |ajuste| ajuste.public_send(columna).to_d }
    else
      ajustes.sum(columna).to_d
    end
  end

  def suma_de_cantidades
    if ajustes.loaded?
      ajustes.sum(&:cantidad)
    else
      ajustes.sum(:cantidad)
    end
  end
end
