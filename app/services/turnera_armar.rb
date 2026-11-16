class TurneraArmar
  ESTADOS = %w[turno_asignado ingresado listo_para_retirar].freeze

  Turno = Data.define(:caso, :estado)
  Dia = Data.define(:fecha, :ingresos, :cupo_diario, :turnos) do
    def supera_cupo?
      ingresos > cupo_diario
    end
  end
  Resultado = Data.define(:errors, :desde, :hasta, :cupo_diario, :dias) do
    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end
  end

  def self.call(fecha: nil)
    new(fecha:).resultado
  end

  def initialize(fecha:)
    @errors = {}
    @fecha = leer_fecha(fecha)
  end

  def resultado
    return Resultado.new(errors: @errors, desde: nil, hasta: nil, cupo_diario: nil, dias: []) if @errors.any?

    desde = @fecha.beginning_of_week(:monday)
    hasta = desde + 6.days
    cupo_diario = ConfiguracionTaller.actual.cupo_diario
    turnos_por_dia = turnos(desde..hasta).group_by { |turno| turno.caso.fecha_turno }

    dias = (desde..hasta).map do |fecha|
      turnos_del_dia = turnos_por_dia.fetch(fecha, [])
      Dia.new(fecha: fecha, ingresos: turnos_del_dia.size, cupo_diario: cupo_diario, turnos: turnos_del_dia)
    end

    Resultado.new(errors: @errors, desde: desde, hasta: hasta, cupo_diario: cupo_diario, dias: dias)
  end

  private

  def turnos(rango)
    Caso.includes(:aseguradora, :asegurado, :vehiculo, orden: :tareas)
        .left_joins(:orden)
        .where(fecha_turno: rango)
        .where("casos.orden_id IS NULL OR ordenes.estado = ?", Orden.estados[:abierta])
        .order(:fecha_turno, :id)
        .map { |caso| Turno.new(caso: caso, estado: estado(caso)) }
  end

  def estado(caso)
    return "turno_asignado" if caso.orden.nil?

    tareas = caso.orden.tareas
    tareas.any? && tareas.all?(&:terminada?) ? "listo_para_retirar" : "ingresado"
  end

  def leer_fecha(valor)
    return Date.current if valor.blank?

    Date.iso8601(valor.to_s)
  rescue Date::Error
    @errors[:fecha] = [ "no es una fecha válida" ]
    nil
  end
end
