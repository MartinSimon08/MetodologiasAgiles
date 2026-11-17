class Caso < ApplicationRecord
  NUMERO_SINIESTRO_MAXIMO = 50
  DESCRIPCION_MAXIMA = 1000

  belongs_to :aseguradora
  belongs_to :asegurado, class_name: "Cliente"
  belongs_to :vehiculo
  belongs_to :orden, optional: true, inverse_of: :caso
  has_many :notificacion_asegurados, dependent: :destroy
  has_many :cambios_turno, -> { order(:created_at, :id) }, class_name: "CambioTurno", inverse_of: :caso, dependent: :destroy

  scope :ocupan_cupo, -> { left_joins(:orden).where("casos.orden_id IS NULL OR ordenes.estado = ?", Orden.estados[:abierta]) }

  normalizes :numero_siniestro, with: ->(numero) { numero.squish.upcase }
  normalizes :descripcion, with: ->(descripcion) { descripcion.strip.presence }

  validates :numero_siniestro, presence: true,
                               length: { maximum: NUMERO_SINIESTRO_MAXIMO },
                               uniqueness: { scope: :aseguradora_id }
  validates :descripcion, length: { maximum: DESCRIPCION_MAXIMA }
  validate :aseguradora_activa, on: :create
  validate :vehiculo_del_asegurado

  private

  def aseguradora_activa
    errors.add(:aseguradora, :desactivada) if aseguradora && !aseguradora.activa?
  end

  def vehiculo_del_asegurado
    errors.add(:vehiculo, :no_es_del_asegurado) if vehiculo && asegurado && vehiculo.cliente_id != asegurado.id
  end
end
