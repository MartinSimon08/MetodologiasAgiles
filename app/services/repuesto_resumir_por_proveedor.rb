class RepuestoResumirPorProveedor
  Resultado = Data.define(:errors, :repuestos, :resumen, :total_comprado) do
    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end
  end

  PROVEEDOR_CLAVE = "LOWER(unaccent(repuestos.proveedor))"
  COSTO_LINEA = "repuestos.costo_unitario * repuestos.cantidad + COALESCE((" \
                "SELECT SUM(ajustes_repuesto.ajuste_costo) FROM ajustes_repuesto " \
                "WHERE ajustes_repuesto.repuesto_id = repuestos.id), 0)"

  def self.call(proveedor: nil, desde: nil, hasta: nil)
    new(proveedor:, desde:, hasta:).resultado
  end

  def self.importe(valor)
    valor.to_d.to_s("F")
  end

  def self.total_linea(repuesto)
    importe(repuesto.costo_vigente)
  end

  def initialize(proveedor:, desde:, hasta:)
    @proveedor = proveedor.to_s.squish.presence
    @errors = {}
    @desde = parse_fecha(desde, :desde)
    @hasta = parse_fecha(hasta, :hasta)
    if @desde && @hasta && @desde > @hasta
      agregar_error(:hasta, "debe ser posterior o igual a la fecha desde")
    end
  end

  def resultado
    if @errors.any?
      return Resultado.new(errors: @errors, repuestos: Repuesto.none, resumen: [], total_comprado: "0.0")
    end

    Resultado.new(
      errors: @errors,
      repuestos: compras,
      resumen: resumen_proveedores,
      total_comprado: self.class.importe(filtrados.sum(COSTO_LINEA))
    )
  end

  private

  def compras
    filtrados.preload(:ajustes, orden: %i[cliente vehiculo]).order(created_at: :desc, id: :desc)
  end

  def resumen_proveedores
    filtrados
      .group(Arel.sql(PROVEEDOR_CLAVE))
      .select(
        Arel.sql("(ARRAY_AGG(repuestos.proveedor ORDER BY repuestos.created_at DESC, repuestos.id DESC))[1] AS nombre"),
        Arel.sql("SUM(#{COSTO_LINEA}) AS total_comprado"),
        Arel.sql("COUNT(*) AS cantidad_compras")
      )
      .order(Arel.sql("SUM(#{COSTO_LINEA}) DESC, nombre ASC NULLS LAST"))
      .map { |fila| serializar_proveedor(fila) }
  end

  def filtrados
    scope = Repuesto.valorizado.vigentes.where.not(orden: Orden.cancelada)
    if @proveedor
      scope = scope.where("unaccent(repuestos.proveedor) ILIKE unaccent(?)", "%#{Repuesto.sanitize_sql_like(@proveedor)}%")
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
    @errors[campo] ||= []
    @errors[campo] << mensaje
  end

  def serializar_proveedor(fila)
    {
      proveedor: fila[:nombre],
      total_comprado: self.class.importe(fila[:total_comprado]),
      cantidad_compras: fila[:cantidad_compras].to_i
    }
  end
end
