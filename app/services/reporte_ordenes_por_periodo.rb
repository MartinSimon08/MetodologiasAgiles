class ReporteOrdenesPorPeriodo
  Resultado = Data.define(:errors, :abiertas, :cerradas) do
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
    return Resultado.new(errors: @errors, abiertas: 0, cerradas: 0) if @errors.any?

    rango = @desde.beginning_of_day..@hasta.end_of_day
    Resultado.new(
      errors: @errors,
      abiertas: Orden.where(created_at: rango).count,
      cerradas: Orden.where(cerrada_en: rango).count
    )
  end

  private

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
