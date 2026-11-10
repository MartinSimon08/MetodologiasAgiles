class ReporteIngresos
  Particion = Data.define(:franquicia_cobrada, :saldo_facturado, :saldo_pendiente, :ingreso_cliente)
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
    @particiones = {}
    @desde = requerir_fecha(desde, :desde)
    @hasta = requerir_fecha(hasta, :hasta)
    if @desde && @hasta && @desde > @hasta
      agregar_error(:hasta, "debe ser posterior o igual a la fecha desde")
    end
  end

  def resultado
    return armar(0, 0, 0, 0) if @errors.any?

    rango = @desde.beginning_of_day..@hasta.end_of_day
    franquicia, clientes = ingresos_registrados(rango)
    facturado, pendiente = saldos_de_ordenes_cerradas(rango)
    armar(franquicia, facturado, pendiente, clientes)
  end

  private

  def ingresos_registrados(rango)
    franquicia = 0.to_d
    clientes = 0.to_d

    Adelanto.where(registrado_en: rango).includes(:orden).group_by(&:orden_id).each_value do |adelantos|
      orden = adelantos.first.orden
      importe = adelantos.sum { |adelanto| adelanto.importe.to_d }
      parte_franquicia, parte_cliente = repartir_adelantos(orden, importe)
      franquicia += parte_franquicia
      clientes += parte_cliente
    end

    [ franquicia, clientes ]
  end

  def saldos_de_ordenes_cerradas(rango)
    facturado = 0.to_d
    pendiente = 0.to_d

    Orden.cerrada.where(cerrada_en: rango).find_each do |orden|
      partes = particion_de(orden)
      facturado += partes.saldo_facturado
      pendiente += partes.saldo_pendiente
    end

    [ facturado, pendiente ]
  end

  def repartir_adelantos(orden, importe)
    partes = particion_de(orden)
    total_adelantos = partes.franquicia_cobrada + partes.ingreso_cliente
    return [ 0.to_d, 0.to_d ] if total_adelantos.zero?

    [
      importe * partes.franquicia_cobrada / total_adelantos,
      importe * partes.ingreso_cliente / total_adelantos
    ]
  end

  def particion_de(orden)
    @particiones[orden.id] ||= particion_provisoria(orden)
  end

  def particion_provisoria(orden)
    # Provisorio hasta HU28. Reemplazar cuando exista la partición real de franquicia y saldo a la aseguradora.
    total_autorizado = orden.cerrada? ? orden.total_cerrado : orden.total
    adelantos = orden.adelantos.sum(:importe).to_d

    if Caso.exists?(orden_id: orden.id)
      Particion.new(
        franquicia_cobrada: adelantos,
        saldo_facturado: 0.to_d,
        saldo_pendiente: total_autorizado.to_d - adelantos,
        ingreso_cliente: 0.to_d
      )
    else
      Particion.new(
        franquicia_cobrada: 0.to_d,
        saldo_facturado: 0.to_d,
        saldo_pendiente: 0.to_d,
        ingreso_cliente: adelantos
      )
    end
  end

  def armar(franquicia, facturado, pendiente, clientes)
    Resultado.new(
      errors: @errors,
      franquicia_cobrada: importe(franquicia),
      saldo_facturado_aseguradoras: importe(facturado),
      saldo_pendiente_aseguradoras: importe(pendiente),
      ingresos_clientes_directos: importe(clientes),
      total_ingresos: importe(franquicia + facturado + clientes)
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
