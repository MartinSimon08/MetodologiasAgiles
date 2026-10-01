class VehiculoBuscar
  def self.call(termino, scope: Vehiculo.all)
    termino = termino.to_s.squish
    return scope.order(:patente, :id) if termino.blank?

    patente = Vehiculo.normalize_value_for(:patente, termino)
    telefono = Cliente.normalize_value_for(:telefono, termino)
    base = scope.joins(:cliente)

    coincidencias = base.where("vehiculos.patente LIKE ?", contiene(patente))
                        .or(base.where("clientes.nombre ILIKE ?", contiene(termino)))
    coincidencias = coincidencias.or(base.where("clientes.telefono LIKE ?", contiene(telefono))) if telefono.match?(/\d/)

    coincidencias.order(prioridad(patente)).order(:patente, :id)
  end

  def self.contiene(valor)
    "%#{Vehiculo.sanitize_sql_like(valor)}%"
  end

  def self.prioridad(patente)
    Arel.sql(Vehiculo.sanitize_sql_array([
      "CASE WHEN vehiculos.patente = ? THEN 0 WHEN vehiculos.patente LIKE ? THEN 1 ELSE 2 END",
      patente, "#{Vehiculo.sanitize_sql_like(patente)}%"
    ]))
  end

  private_class_method :contiene, :prioridad
end
