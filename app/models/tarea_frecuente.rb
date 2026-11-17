class TareaFrecuente < ApplicationRecord
  self.table_name = "tareas_frecuentes"

  normalizes :descripcion, with: ->(descripcion) { descripcion.strip }

  scope :buscar, lambda { |termino|
    termino = termino.to_s.squish
    next all if termino.blank?

    where("unaccent(tareas_frecuentes.descripcion) ILIKE unaccent(?)", "%#{sanitize_sql_like(termino)}%")
  }

  validates :descripcion, presence: true, uniqueness: { case_sensitive: false }
  validates :precio_sugerido, presence: true, numericality: { greater_than: 0 }
end
