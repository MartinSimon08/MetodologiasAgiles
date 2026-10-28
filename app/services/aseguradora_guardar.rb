class AseguradoraGuardar
  def self.call(aseguradora: Aseguradora.new, **atributos)
    aseguradora.update!(atributos)
    aseguradora
  rescue ActiveRecord::RecordNotUnique
    aseguradora.errors.add(:nombre, :taken)
    raise ActiveRecord::RecordInvalid, aseguradora
  end
end
