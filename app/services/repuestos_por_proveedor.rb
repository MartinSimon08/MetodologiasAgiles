class RepuestosPorProveedor
  def self.call(proveedor: nil, desde: nil, hasta: nil)
    new(proveedor:, desde:, hasta:)
  end

  attr_reader :errors

  def initialize(proveedor: nil, desde: nil, hasta: nil)
    @proveedor = proveedor.to_s.squish.presence
    @errors = {}
    @desde = parse_fecha(desde, :desde)
    @hasta = parse_fecha(hasta, :hasta)
    if @desde && @hasta && @desde > @hasta
      agregar_error(:hasta, "debe ser posterior o igual a la fecha desde")
    end
  end

  def valid?
    errors.empty?
  end

  def invalid?
    !valid?
  end

  def repuestos
    asegurar_valida!
    filtrados.includes(orden: %i[cliente vehiculo]).order(created_at: :desc, id: :desc)
  end

  def resumen
    asegurar_valida!
    filtrados
      .group(:proveedor)
      .select(:proveedor, "SUM(costo_unitario * cantidad) AS total_comprado", "COUNT(*) AS cantidad_compras")
      .order(Arel.sql("SUM(costo_unitario * cantidad) DESC, proveedor ASC NULLS LAST"))
      .map { |fila| serializar_proveedor(fila) }
  end

  def total_comprado
    asegurar_valida!
    decimal(filtrados.sum("costo_unitario * cantidad"))
  end

  private

  def filtrados
    scope = Repuesto.valorizado
    if @proveedor
      scope = scope.where("proveedor ILIKE ?", "%#{Repuesto.sanitize_sql_like(@proveedor)}%")
    end
    scope = scope.where(created_at: @desde.beginning_of_day..) if @desde
    scope = scope.where(created_at: ..@hasta.end_of_day) if @hasta
    scope
  end

  def parse_fecha(valor, campo)
    return if valor.blank?

    Date.iso8601(valor.to_s)
  rescue Date::Error
    agregar_error(campo, "no es una fecha válida")
    nil
  end

  def agregar_error(campo, mensaje)
    errors[campo] ||= []
    errors[campo] << mensaje
  end

  def asegurar_valida!
    raise ArgumentError, "consulta inválida" if invalid?
  end

  def serializar_proveedor(fila)
    {
      proveedor: fila.proveedor,
      total_comprado: decimal(fila.total_comprado),
      cantidad_compras: fila.cantidad_compras.to_i
    }
  end

  def decimal(valor)
    valor.to_d.to_s("F")
  end
end
