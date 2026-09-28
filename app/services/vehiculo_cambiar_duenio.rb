class VehiculoCambiarDuenio
  def self.call(vehiculo:, cliente_id:)
    vehiculo.with_lock do
      if vehiculo.cliente_id == cliente_id.to_i
        vehiculo.errors.add(:cliente, :mismo_duenio)
        raise ActiveRecord::RecordInvalid, vehiculo
      end

      vehiculo.update!(cliente: Cliente.find_by(id: cliente_id))
    end
    vehiculo
  end
end
