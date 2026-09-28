class Vehiculo < ApplicationRecord
  PATENTE_FORMATO = /\A[A-Z0-9]{5,10}\z/
  ANIO_MINIMO = 1900

  belongs_to :cliente

  normalizes :patente, with: ->(patente) { patente.upcase.gsub(/[\s\-.]/, "") }
  normalizes :marca, :modelo, with: ->(valor) { valor.squish.presence }

  validates :patente, presence: true,
                      uniqueness: true,
                      format: { with: PATENTE_FORMATO, allow_blank: true }
  validates :marca, :modelo, length: { maximum: 100 }
  validates :anio, numericality: { only_integer: true, greater_than_or_equal_to: ANIO_MINIMO,
                                   less_than_or_equal_to: ->(_) { Date.current.year + 1 } },
                   allow_nil: true
  validates :kilometraje, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                          less_than: 10_000_000 },
                          allow_nil: true
end
