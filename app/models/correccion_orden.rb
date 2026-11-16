class CorreccionOrden < ApplicationRecord
  self.table_name = "correcciones_orden"

  MOTIVO_MAXIMO = 500
  CAMPOS = %w[total_cerrado franquicia].freeze

  belongs_to :orden
  belongs_to :usuario

  normalizes :motivo, with: ->(motivo) { motivo.squish }

  validates :campo, inclusion: { in: CAMPOS }
  validates :motivo, presence: true, length: { maximum: MOTIVO_MAXIMO }
end
