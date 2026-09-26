class ClienteRegistrar
  def self.call(nombre:, telefono:, email: nil)
    cliente = Cliente.new(nombre: nombre, telefono: telefono, email: email)
    cliente.save!
    cliente
  rescue ActiveRecord::RecordNotUnique
    cliente.errors.add(:telefono, :taken)
    raise ActiveRecord::RecordInvalid, cliente
  end
end
