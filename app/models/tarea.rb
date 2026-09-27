class Tarea < ApplicationRecord
  belongs_to :orden
  belongs_to :mecanico, class_name: "Usuario", optional: true

  enum :estado, { pendiente: "pendiente", en_curso: "en_curso", terminada: "terminada" }, validate: true

  validates :descripcion, presence: true
  validate :orden_abierta, on: :create

  private

  def orden_abierta
    errors.add(:orden, :cerrada) if orden&.cerrada?
  end
end
