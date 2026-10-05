class Tarea < ApplicationRecord
  belongs_to :orden
  belongs_to :mecanico, class_name: "Usuario", optional: true

  enum :estado, { pendiente: "pendiente", en_curso: "en_curso", terminada: "terminada" }, validate: true

  validates :descripcion, presence: true
  validates :precio, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :orden_abierta, on: :create

  private

  def orden_abierta
    errors.add(:orden, orden.estado.to_sym) if orden && !orden.abierta?
  end
end
