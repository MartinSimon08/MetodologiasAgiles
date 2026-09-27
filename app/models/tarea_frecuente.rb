class TareaFrecuente < ApplicationRecord
  normalizes :descripcion, with: ->(descripcion) { descripcion.strip }

  validates :descripcion, presence: true, uniqueness: { case_sensitive: false }
  validates :precio_sugerido, presence: true, numericality: { greater_than: 0 }
end
