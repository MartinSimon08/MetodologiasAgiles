class Adelanto < ApplicationRecord
  belongs_to :orden
  belongs_to :registrado_por, class_name: "Usuario"

  validates :importe, numericality: { greater_than: 0 }, allow_nil: false
  validates :registrado_en, presence: true
  validate :orden_abierta

  private

  def orden_abierta
    errors.add(:orden, :must_be_open) if orden && !orden.abierta?
  end
end
