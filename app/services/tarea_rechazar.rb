class TareaRechazar
  def self.call(tarea:)
    tarea.with_lock do
      tarea.errors.add(:orden, tarea.orden.estado.to_sym) unless tarea.orden.abierta?
      raise ActiveRecord::RecordInvalid, tarea if tarea.errors.any?

      mecanico_a_avisar = tarea.mecanico if tarea.en_curso?

      if tarea.en_curso?
        tarea.update!(aprobacion: :rechazada, estado: :pendiente, mecanico: nil, tomada_en: nil)
      else
        tarea.update!(aprobacion: :rechazada)
      end

      notificar(tarea, mecanico_a_avisar) if mecanico_a_avisar
    end

    tarea
  end

  def self.notificar(tarea, mecanico)
    TareasChannel.broadcast_to(mecanico, {
      tipo: "tarea_rechazada",
      id: tarea.id,
      descripcion: tarea.descripcion,
      orden_id: tarea.orden_id
    })
  end
end
