class RepuestoCatalogo < ApplicationRecord
  self.table_name = "repuestos_catalogo"

  has_many :repuestos, dependent: :restrict_with_error

  normalizes :nombre, with: ->(nombre) { nombre.squish.downcase }

  validates :nombre, presence: true, length: { maximum: 200 }
  validates :ultimo_costo, numericality: { greater_than_or_equal_to: 0, less_than: 10_000_000_000 }
end
