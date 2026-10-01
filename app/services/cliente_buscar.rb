class ClienteBuscar
  def self.call(termino)
    termino = termino.to_s.squish
    return Cliente.order(:nombre, :id) if termino.blank?

    patente = Vehiculo.normalize_value_for(:patente, termino)
    telefono = Cliente.normalize_value_for(:telefono, termino)

    coincidencias = Cliente.where("clientes.nombre ILIKE ?", contiene(termino))
                           .or(Cliente.where(id: Vehiculo.where("vehiculos.patente LIKE ?", contiene(patente))
                                                         .select(:cliente_id)))
    coincidencias = coincidencias.or(Cliente.where("clientes.telefono LIKE ?", contiene(telefono))) if telefono.match?(/\d/)

    coincidencias.order(prioridad(patente, telefono)).order(:nombre, :id)
  end

  def self.contiene(valor)
    "%#{Cliente.sanitize_sql_like(valor)}%"
  end

  def self.prioridad(patente, telefono)
    Arel.sql(Cliente.sanitize_sql_array([
      "CASE WHEN clientes.telefono = ? OR clientes.id IN (SELECT cliente_id FROM vehiculos WHERE patente = ?) " \
      "THEN 0 ELSE 1 END",
      telefono, patente
    ]))
  end

  private_class_method :contiene, :prioridad
end
