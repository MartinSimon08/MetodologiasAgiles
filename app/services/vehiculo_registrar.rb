class VehiculoRegistrar
  def self.call(**atributos)
    vehiculo = Vehiculo.new(atributos)
    vehiculo.save!
    vehiculo
  rescue ActiveRecord::RecordNotUnique
    vehiculo.errors.add(:patente, :taken)
    raise ActiveRecord::RecordInvalid, vehiculo
  end
end
