class Repuesto < ApplicationRecord
  belongs_to :orden
  belongs_to :repuesto_catalogo, optional: true
  belongs_to :registrado_por, class_name: "Usuario"

  normalizes :descripcion, with: ->(descripcion) { descripcion.squish }

  validates :descripcion, presence: true, length: { maximum: 200 }
  validates :cantidad, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 2_147_483_647 }
  validates :costo_unitario, numericality: { greater_than_or_equal_to: 0, less_than: 10_000_000_000 }
  validates :margen, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
