class RepuestoCatalogo < ApplicationRecord
  self.table_name = "repuestos_catalogo"

  has_many :repuestos, dependent: :nullify

  normalizes :nombre, with: ->(nombre) { nombre.squish.downcase }

  validates :nombre, presence: true, length: { maximum: 200 }, uniqueness: true
  validates :precio, numericality: { greater_than_or_equal_to: 0, less_than: 10_000_000_000 }
end
