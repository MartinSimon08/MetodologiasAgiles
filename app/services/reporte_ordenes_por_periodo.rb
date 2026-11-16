class ReporteOrdenesPorPeriodo
  include ValidaPeriodo

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
    requerir_periodo(desde, hasta)
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
end
