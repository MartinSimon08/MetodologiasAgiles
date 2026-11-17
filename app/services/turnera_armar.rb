class TurneraArmar
  ESTADOS = %w[turno_asignado ingresado listo_para_retirar].freeze
  PERIODOS = %w[semana mes].freeze

  Turno = Data.define(:caso, :estado)
  Dia = Data.define(:fecha, :ingresos, :cupo_diario, :turnos) do
    def supera_cupo?
      ingresos > cupo_diario
    end
  end
  Resultado = Data.define(:errors, :periodo, :desde, :hasta, :cupo_diario, :dias) do
    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end
  end

  def self.call(fecha: nil, periodo: nil)
    new(fecha:, periodo:).resultado
  end

  def initialize(fecha:, periodo:)
    @errors = {}
    @fecha = leer_fecha(fecha)
    @periodo = leer_periodo(periodo)
  end

  def resultado
    if @errors.any?
      return Resultado.new(errors: @errors, periodo: @periodo, desde: nil, hasta: nil, cupo_diario: nil, dias: [])
    end

    desde, hasta = rango
    cupo_diario = ConfiguracionTaller.actual.cupo_diario
    turnos_por_dia = turnos(desde..hasta).group_by { |turno| turno.caso.fecha_turno }

    dias = (desde..hasta).map do |fecha|
      turnos_del_dia = turnos_por_dia.fetch(fecha, [])
      Dia.new(fecha: fecha, ingresos: turnos_del_dia.size, cupo_diario: cupo_diario, turnos: turnos_del_dia)
    end

    Resultado.new(errors: @errors, periodo: @periodo, desde: desde, hasta: hasta, cupo_diario: cupo_diario, dias: dias)
  end

  private

  def rango
    return [ @fecha.beginning_of_week(:monday), @fecha.end_of_week(:monday) ] if @periodo == "semana"

    [ @fecha.beginning_of_month.beginning_of_week(:monday), @fecha.end_of_month.end_of_week(:monday) ]
  end

  def turnos(rango)
    Caso.includes(:aseguradora, :asegurado, :vehiculo, orden: :tareas)
        .ocupan_cupo
        .where(fecha_turno: rango)
        .order(:fecha_turno, :id)
        .map { |caso| Turno.new(caso: caso, estado: estado(caso)) }
  end

  def estado(caso)
    return "turno_asignado" if caso.orden.nil?

    tareas = caso.orden.tareas
    tareas.any? && tareas.all?(&:terminada?) ? "listo_para_retirar" : "ingresado"
  end

  def leer_periodo(valor)
    return "semana" if valor.blank?
    return valor.to_s if PERIODOS.include?(valor.to_s)

    @errors[:periodo] = [ "no es un período válido" ]
    nil
  end

  def leer_fecha(valor)
    return Date.current if valor.blank?

    Date.iso8601(valor.to_s)
  rescue Date::Error
    @errors[:fecha] = [ "no es una fecha válida" ]
    nil
  end
end
