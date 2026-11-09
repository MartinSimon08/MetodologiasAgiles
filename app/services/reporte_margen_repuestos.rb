class ReporteMargenRepuestos
  Resultado = Data.define(:errors, :margen_total) do
    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end
  end

  MARGEN_LINEA = "repuestos.precio_cliente - (repuestos.costo_unitario * repuestos.cantidad) + COALESCE((" \
                 "SELECT SUM(ajustes_repuesto.ajuste_precio_cliente - ajustes_repuesto.ajuste_costo) " \
                 "FROM ajustes_repuesto WHERE ajustes_repuesto.repuesto_id = repuestos.id), 0)"

  def self.call(desde: nil, hasta: nil)
    new(desde:, hasta:).resultado
  end

  def self.importe(valor)
    valor.to_d.to_s("F")
  end

  def initialize(desde:, hasta:)
    @errors = {}
    @desde = requerir_fecha(desde, :desde)
    @hasta = requerir_fecha(hasta, :hasta)
    if @desde && @hasta && @desde > @hasta
      agregar_error(:hasta, "debe ser posterior o igual a la fecha desde")
    end
  end

  def resultado
    return Resultado.new(errors: @errors, margen_total: "0.0") if @errors.any?

    Resultado.new(errors: @errors, margen_total: self.class.importe(repuestos_del_periodo.sum(MARGEN_LINEA)))
  end

  private

  def repuestos_del_periodo
    rango = @desde.beginning_of_day..@hasta.end_of_day
    Repuesto.valorizado.vigentes.where.not(aprobacion: :rechazado)
      .joins(:orden)
      .merge(Orden.where(created_at: rango).where.not(estado: :cancelada))
  end

  def requerir_fecha(valor, campo)
    if valor.blank?
      agregar_error(campo, "no puede estar en blanco")
      return nil
    end

    Date.iso8601(valor.to_s)
  rescue Date::Error
    agregar_error(campo, "no es una fecha válida")
    nil
  end

  def agregar_error(campo, mensaje)
    @errors[campo] ||= []
    @errors[campo] << mensaje
  end
end
