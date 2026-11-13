class CasoIngresar
  def self.call(caso_id:)
    caso = Caso.find(caso_id)
    caso.with_lock do
      caso.errors.add(:base, :ya_ingresado) if caso.orden_id
      caso.errors.add(:base, :sin_turno) if caso.fecha_turno.nil?
      raise ActiveRecord::RecordInvalid, caso if caso.errors.any?

      orden = OrdenAbrir.call(vehiculo_id: caso.vehiculo_id, motivo: caso.descripcion || "Siniestro #{caso.numero_siniestro}")
      caso.update!(orden: orden)
    end
    caso
  end
end
