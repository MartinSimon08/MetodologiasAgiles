class ConsultaCasosAseguradora
  Fila = Data.define(:caso, :total_autorizado, :franquicia_cobrada, :saldo_pendiente)
  Totales = Data.define(:total_autorizado, :franquicia_cobrada, :saldo_pendiente)
  Particion = Data.define(:total_autorizado, :franquicia_cobrada, :saldo_facturado, :saldo_pendiente)
  Resultado = Data.define(:errors, :filas, :totales) do
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

  def self.importe(valor)
    valor.to_d.to_s("F")
  end

  def initialize(aseguradora_id:, desde:, hasta:)
    @errors = {}
    @aseguradora = requerir_aseguradora(aseguradora_id)
    @desde = requerir_fecha(desde, :desde)
    @hasta = requerir_fecha(hasta, :hasta)
    if @desde && @hasta && @desde > @hasta
      agregar_error(:hasta, "debe ser posterior o igual a la fecha desde")
    end
  end

  def resultado
    filas = @errors.any? ? [] : filas_del_periodo
    Resultado.new(errors: @errors, filas: filas, totales: totales_de(filas))
  end

  private

  def filas_del_periodo
    rango = @desde.beginning_of_day..@hasta.end_of_day
    Caso.where(aseguradora: @aseguradora, created_at: rango)
        .includes(:asegurado, :vehiculo, orden: :adelantos)
        .order(created_at: :asc, id: :asc)
        .map { |caso| fila_de(caso) }
  end

  def fila_de(caso)
    montos = caso.orden ? particion_provisoria(caso.orden) : particion_en_cero
    Fila.new(
      caso: caso,
      total_autorizado: self.class.importe(montos.total_autorizado),
      franquicia_cobrada: self.class.importe(montos.franquicia_cobrada),
      saldo_pendiente: self.class.importe(montos.saldo_pendiente)
    )
  end

  def particion_en_cero
    Particion.new(total_autorizado: 0, franquicia_cobrada: 0, saldo_facturado: 0, saldo_pendiente: 0)
  end

  def particion_provisoria(orden)
    # Provisorio hasta HU28. Reemplazar cuando exista la partición real de franquicia y saldo a la aseguradora.
    total_autorizado = (orden.cerrada? ? orden.total_cerrado : orden.total).to_d
    if orden.caso
      franquicia_cobrada = orden.adelantos.sum(:importe).to_d
      saldo_facturado = 0.to_d
      saldo_pendiente = total_autorizado - franquicia_cobrada
    else
      franquicia_cobrada = 0.to_d
      saldo_facturado = 0.to_d
      saldo_pendiente = 0.to_d
    end

    Particion.new(total_autorizado:, franquicia_cobrada:, saldo_facturado:, saldo_pendiente:)
  end

  def totales_de(filas)
    Totales.new(
      total_autorizado: self.class.importe(filas.sum { |fila| fila.total_autorizado.to_d }),
      franquicia_cobrada: self.class.importe(filas.sum { |fila| fila.franquicia_cobrada.to_d }),
      saldo_pendiente: self.class.importe(filas.sum { |fila| fila.saldo_pendiente.to_d })
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
