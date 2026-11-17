class CambioTurno < ApplicationRecord
  self.table_name = "cambios_turno"

  belongs_to :caso, inverse_of: :cambios_turno
  belongs_to :registrado_por, class_name: "Usuario"

  validates :fecha_nueva, presence: true

  def reprogramacion?
    fecha_anterior.present?
  end
end
