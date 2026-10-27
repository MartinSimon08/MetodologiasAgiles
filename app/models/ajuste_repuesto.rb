class AjusteRepuesto < ApplicationRecord
  self.table_name = "ajustes_repuesto"

  MOTIVO_MAXIMO = 500
  COSTO_MAXIMO = 10_000_000_000
  ATRIBUTOS_DE_ENTRADA = %i[tipo cantidad costo_unitario motivo orden repuesto registrado_en registrado_por].freeze

  belongs_to :repuesto, inverse_of: :ajustes
  belongs_to :registrado_por, class_name: "Usuario"
  delegate :orden, to: :repuesto, allow_nil: true

  enum :tipo, { devolucion: "devolucion", cambio: "cambio" }, validate: true

  normalizes :motivo, with: ->(motivo) { motivo.squish }

  validates :cantidad, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 2_147_483_647 }
  validates :costo_unitario, numericality: { greater_than_or_equal_to: 0, less_than: COSTO_MAXIMO }
  validates :motivo, presence: true, length: { maximum: MOTIVO_MAXIMO }
  validates :registrado_en, presence: true
  validates :ajuste_costo, :ajuste_precio_cliente, numericality: true, if: :calculable?
  validates :precio_original, numericality: { greater_than_or_equal_to: 0 }, if: :calculable?

  validate :repuesto_valorizado
  validate :repuesto_sigue_en_la_orden
  validate :orden_permite_ajuste
  validate :cantidad_disponible
  validate :total_no_queda_bajo_adelantos
  validate :rechaza_sin_montos

  before_validation :calcular_ajustes

  private

  def calcular_ajustes
    self.precio_original = nil
    self.ajuste_costo = nil
    self.ajuste_precio_cliente = nil
    return unless calculable?

    self.precio_original = precio_original_de_la_cantidad
    if devolucion?
      self.ajuste_precio_cliente = -precio_original
      self.ajuste_costo = -(costo_decimal * cantidad_entera).round(2)
    else
      precio_nuevo = (costo_decimal * cantidad_entera * (1 + repuesto.margen.to_d / 100)).round(2)
      self.ajuste_precio_cliente = precio_nuevo - precio_original
      self.ajuste_costo = ((costo_decimal - repuesto.costo_unitario.to_d) * cantidad_entera).round(2)
    end
  end

  def precio_original_de_la_cantidad
    previos = ajustes_previos
    if previos.sum(:cantidad).to_i + cantidad_entera == repuesto.cantidad
      repuesto.precio_cliente.to_d - previos.sum(:precio_original).to_d
    else
      (repuesto.precio_cliente.to_d * cantidad_entera / repuesto.cantidad).round(2)
    end
  end

  def ajustes_previos
    repuesto.ajustes.where.not(id: id)
  end

  def calculable?
    return false unless repuesto&.valorizado?
    return false unless repuesto.margen.present? && repuesto.precio_cliente.present? && repuesto.costo_unitario.present?
    return false unless tipo_conocido? && cantidad_entera

    costo = costo_decimal
    costo.present? && costo >= 0 && costo < COSTO_MAXIMO
  end

  def tipo_conocido?
    self.class.tipos.key?(tipo)
  end

  def cantidad_entera
    crudo = cantidad_before_type_cast
    if crudo.is_a?(String)
      return nil unless crudo.match?(/\A[+-]?\d+\z/)

      return Integer(crudo, 10)
    end

    cantidad if cantidad.is_a?(Integer) && cantidad.positive?
  end

  def costo_decimal
    valor = self.class.type_for_attribute(:costo_unitario).cast(costo_unitario)
    valor if valor.is_a?(BigDecimal)
  end

  def repuesto_valorizado
    return if repuesto.nil? || repuesto.valorizado?

    errors.add(:repuesto, :sin_valorizar)
  end

  def repuesto_sigue_en_la_orden
    return if repuesto.nil? || repuesto.quitado_en.blank?

    errors.add(:repuesto, :ya_quitado)
  end

  def orden_permite_ajuste
    orden = repuesto&.orden
    return if orden.nil? || orden.abierta?

    errors.add(:orden, orden.cancelada? ? :cancelada : :cerrada_congelada)
  end

  def cantidad_disponible
    return unless cantidad_entera
    return if repuesto.nil? || cantidad_dentro_de_lo_disponible?

    errors.add(:cantidad, :supera_disponible)
  end

  def cantidad_dentro_de_lo_disponible?
    usadas = ajustes_previos.sum(:cantidad).to_i
    cantidad_entera <= repuesto.cantidad - usadas
  end

  def total_no_queda_bajo_adelantos
    return unless calculable? && cantidad_dentro_de_lo_disponible? && !ajuste_precio_cliente.nil?

    orden = repuesto.orden
    delta = repuesto.aprobacion_rechazado? ? 0.to_d : ajuste_precio_cliente.to_d
    resultante = orden.total + delta
    return if resultante >= orden.adelantos.sum(:importe).to_d

    errors.add(:base, :deja_total_bajo_adelantos)
  end

  def rechaza_sin_montos
    return if montos_calculados?
    return if ATRIBUTOS_DE_ENTRADA.any? { |atributo| errors[atributo].any? }

    errors.add(:base, :no_calculado)
  end

  def montos_calculados?
    !ajuste_costo.nil? && !ajuste_precio_cliente.nil? && !precio_original.nil?
  end
end
