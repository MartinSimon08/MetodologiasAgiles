class Repuesto < ApplicationRecord
  belongs_to :orden
  belongs_to :repuesto_catalogo, optional: true
  belongs_to :registrado_por, class_name: "Usuario"
  belongs_to :quitado_por, class_name: "Usuario", optional: true, inverse_of: :repuestos_quitados

  enum :estado, { pendiente_de_valorizar: "pendiente_de_valorizar", valorizado: "valorizado" },
    validate: true, default: :valorizado

  scope :vigentes, -> { where(quitado_en: nil) }
  scope :quitados, -> { where.not(quitado_en: nil) }

  normalizes :descripcion, with: ->(descripcion) { descripcion.squish }
  normalizes :proveedor, with: ->(proveedor) { proveedor.squish.presence }

  validates :descripcion, presence: true, length: { maximum: 200 }
  validates :cantidad, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 2_147_483_647 }
  validates :costo_unitario, numericality: { greater_than_or_equal_to: 0, less_than: 10_000_000_000 }, allow_nil: true
  validates :margen, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :costo_unitario, :margen, presence: true, if: :valorizado?
  validates :quitado_en, presence: true, if: :quitado_por_id?
  validates :quitado_por, presence: true, if: :quitado_en?
end
