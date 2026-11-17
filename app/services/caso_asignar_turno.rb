class CasoAsignarTurno
  def self.call(caso_id:, fecha_turno:, registrado_por:)
    new(caso_id:, fecha_turno:, registrado_por:).call
  end

  def initialize(caso_id:, fecha_turno:, registrado_por:)
    @caso = Caso.find(caso_id)
    @valor = fecha_turno
    @registrado_por = registrado_por
  end

  def call
    Caso.transaction do
      configuracion = ConfiguracionTaller.actual.lock!
      @caso.lock!
      fecha = leer_fecha
      validar(fecha, configuracion.cupo_diario) if fecha
      raise ActiveRecord::RecordInvalid, @caso if @caso.errors.any?

      @caso.cambios_turno.create!(fecha_anterior: @caso.fecha_turno, fecha_nueva: fecha, registrado_por: @registrado_por)
      @caso.update!(fecha_turno: fecha)
    end
    @caso
  end

  private

  def leer_fecha
    if @valor.blank?
      @caso.errors.add(:fecha_turno, :blank)
      return
    end

    Date.iso8601(@valor.to_s)
  rescue Date::Error
    @caso.errors.add(:fecha_turno, :invalid)
    nil
  end

  def validar(fecha, cupo_diario)
    return @caso.errors.add(:base, :turno_de_caso_ingresado) if @caso.orden_id
    return @caso.errors.add(:fecha_turno, :pasada) if fecha < Date.current
    return @caso.errors.add(:fecha_turno, :misma_fecha) if fecha == @caso.fecha_turno

    ingresos = Caso.ocupan_cupo.where(fecha_turno: fecha).count
    @caso.errors.add(:fecha_turno, :sin_cupo, ingresos:, cupo: cupo_diario) if ingresos >= cupo_diario
  end
end
