class OrdenCancelar
  Resultado = Data.define(:orden, :tareas_liberadas)

  def self.call(orden:)
    orden.with_lock do
      unless orden.abierta?
        orden.errors.add(:base, orden.cancelada? ? :ya_cancelada : :cerrada_no_cancelable)
        raise ActiveRecord::RecordInvalid, orden
      end

      tareas = orden.tareas.order(:id).lock.to_a.select(&:en_curso?).map { |tarea| TareaLiberar.call(tarea: tarea) }
      orden.update!(estado: :cancelada, cancelada_en: Time.current)

      Resultado.new(orden: orden, tareas_liberadas: tareas)
    end
  end
end
