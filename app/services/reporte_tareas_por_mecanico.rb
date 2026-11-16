class ReporteTareasPorMecanico
  include ValidaPeriodo

  Fila = Data.define(:mecanico, :tomadas, :completadas)
  Resultado = Data.define(:errors, :filas) do
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
    return Resultado.new(errors: @errors, filas: []) if @errors.any?

    Resultado.new(errors: @errors, filas: filas)
  end

  private

  def filas
    rango = @desde.beginning_of_day..@hasta.end_of_day
    tomadas = Tarea.where(tomada_en: rango).where.not(mecanico_id: nil).group(:mecanico_id).count
    completadas = Tarea.where(terminada_en: rango).where.not(mecanico_id: nil).group(:mecanico_id).count

    Usuario.mecanico.order(:nombre, :id).map do |mecanico|
      Fila.new(
        mecanico: mecanico,
        tomadas: tomadas.fetch(mecanico.id, 0),
        completadas: completadas.fetch(mecanico.id, 0)
      )
    end
  end
end
