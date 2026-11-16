class CasoConsultarPorAseguradora
  include ValidaPeriodo

  Fila = Data.define(:caso, :total_autorizado, :franquicia_cobrada, :saldo_pendiente)
  Totales = Data.define(:total_autorizado, :franquicia_cobrada, :saldo_pendiente)
  Particion = Data.define(:total_autorizado, :franquicia_cobrada, :saldo_pendiente)
  Resultado = Data.define(:errors, :aseguradora, :filas, :totales) do
    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end
  end

  def self.call(aseguradora_id: nil, desde: nil, hasta: nil)
    new(aseguradora_id:, desde:, hasta:).resultado
  end

  def initialize(aseguradora_id:, desde:, hasta:)
    @errors = {}
    @aseguradora = requerir_aseguradora(aseguradora_id)
    requerir_periodo(desde, hasta)
  end

  def resultado
    filas = @errors.any? ? [] : filas_del_periodo
    Resultado.new(errors: @errors, aseguradora: @aseguradora, filas: filas, totales: totales_de(filas))
  end

  private

  def filas_del_periodo
    rango = @desde.beginning_of_day..@hasta.end_of_day
    Caso.where(aseguradora: @aseguradora, created_at: rango)
        .includes(:asegurado, :vehiculo, :orden)
        .order(created_at: :asc, id: :asc)
        .map { |caso| fila_de(caso) }
  end

  def fila_de(caso)
    montos = caso.orden.nil? || caso.orden.cancelada? ? particion_en_cero : particion(caso.orden)
    Fila.new(
      caso: caso,
      total_autorizado: Dinero.importe(montos.total_autorizado),
      franquicia_cobrada: Dinero.importe(montos.franquicia_cobrada),
      saldo_pendiente: Dinero.importe(montos.saldo_pendiente)
    )
  end

  def particion_en_cero
    Particion.new(total_autorizado: 0, franquicia_cobrada: 0, saldo_pendiente: 0)
  end

  def particion(orden)
    total_autorizado = orden.total

    Particion.new(
      total_autorizado:,
      franquicia_cobrada: orden.franquicia.to_d,
      saldo_pendiente: orden.saldo_a_facturar(total: total_autorizado)
    )
  end

  def totales_de(filas)
    Totales.new(
      total_autorizado: Dinero.importe(filas.sum { |fila| fila.total_autorizado.to_d }),
      franquicia_cobrada: Dinero.importe(filas.sum { |fila| fila.franquicia_cobrada.to_d }),
      saldo_pendiente: Dinero.importe(filas.sum { |fila| fila.saldo_pendiente.to_d })
    )
  end

  def requerir_aseguradora(valor)
    if valor.blank?
      agregar_error(:aseguradora, "no puede estar en blanco")
      return nil
    end

    id = Integer(valor, exception: false)
    aseguradora = Aseguradora.find_by(id: id) if id&.positive?
    return aseguradora if aseguradora

    agregar_error(:aseguradora, "no es válida")
    nil
  end
end
