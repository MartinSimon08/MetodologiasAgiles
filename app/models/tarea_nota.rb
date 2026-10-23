class TareaNota < ApplicationRecord
  CONTENIDO_MAXIMO = 1000

  belongs_to :tarea
  belongs_to :registrado_por, class_name: "Usuario"

  delegate :orden, to: :tarea

  normalizes :contenido, with: ->(contenido) { contenido.strip }

  validates :contenido, presence: true, length: { maximum: CONTENIDO_MAXIMO }
end
