class OrdenBuscar
  def self.call(termino, scope: Orden.all)
    termino = termino.to_s.squish
    return scope if termino.blank?

    patente = Vehiculo.normalize_value_for(:patente, termino)
    telefono = Cliente.normalize_value_for(:telefono, termino)
    base = scope.joins(:cliente, :vehiculo)

    coincidencias = base.where("unaccent(clientes.nombre) ILIKE unaccent(?)", contiene(termino))
                        .or(base.where("unaccent(concat_ws(' ', vehiculos.marca, vehiculos.modelo)) ILIKE unaccent(?)",
                                       contiene(termino)))
    coincidencias = coincidencias.or(base.where("vehiculos.patente LIKE ?", contiene(patente))) if patente.present?
    coincidencias = coincidencias.or(base.where("clientes.telefono LIKE ?", contiene(telefono))) if telefono.match?(/\d/)
    coincidencias
  end

  def self.contiene(valor)
    "%#{Orden.sanitize_sql_like(valor)}%"
  end

  private_class_method :contiene
end
