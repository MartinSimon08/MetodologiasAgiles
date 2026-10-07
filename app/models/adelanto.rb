class Adelanto < ApplicationRecord
  belongs_to :orden
  belongs_to :registrado_por, class_name: "Usuario"

  validates :importe, numericality: { greater_than: 0 }, allow_nil: false
  validates :registrado_en, presence: true
  validate :orden_abierta
  validate :importe_dentro_del_monto_final

  private

  def orden_abierta
    errors.add(:orden, :must_be_open) if orden && !orden.abierta?
  end

  def importe_dentro_del_monto_final
    return if orden.nil? || importe.nil?

    acumulado = orden.adelantos.where.not(id: id).sum(:importe).to_d
    return if importe.to_d + acumulado <= orden.total

    errors.add(:importe, :mayor_que_monto_final)
  end
end
