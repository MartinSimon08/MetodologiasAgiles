class ReporteIngresos
  Resultado = Data.define(
    :errors,
    :franquicia_cobrada,
    :saldo_facturado_aseguradoras,
    :saldo_pendiente_aseguradoras,
    :ingresos_clientes_directos,
    :total_ingresos
  ) do
    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end
  end

  def self.call(desde: nil, hasta: nil)
    new(desde:, hasta:).resultado
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
    return armar(0, 0, 0) if @errors.any?

    rango = @desde.beginning_of_day..@hasta.end_of_day
    franquicia, pendiente = de_casos_cerrados(rango)
    armar(franquicia, pendiente, ingresos_clientes_directos(rango))
  end

  private

  def de_casos_cerrados(rango)
    franquicia = 0.to_d
    pendiente = 0.to_d

    Orden.cerrada.where(cerrada_en: rango).joins(:caso).find_each do |orden|
      franquicia += orden.franquicia.to_d
      pendiente += orden.saldo_a_facturar
    end

    [ franquicia, pendiente ]
  end

  def ingresos_clientes_directos(rango)
    Adelanto.where(registrado_en: rango)
            .where.not(orden_id: Caso.where.not(orden_id: nil).select(:orden_id))
            .sum(:importe)
            .to_d
  end

  def armar(franquicia, pendiente, clientes)
    Resultado.new(
      errors: @errors,
      franquicia_cobrada: importe(franquicia),
      saldo_facturado_aseguradoras: importe(0),
      saldo_pendiente_aseguradoras: importe(pendiente),
      ingresos_clientes_directos: importe(clientes),
      total_ingresos: importe(franquicia + clientes)
    )
  end

  def importe(valor)
    valor.to_d.to_s("F")
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
