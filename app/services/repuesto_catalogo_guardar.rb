class RepuestoCatalogoGuardar
  def self.call(repuesto: RepuestoCatalogo.new, **atributos)
    repuesto.update!(atributos)
    repuesto
  rescue ActiveRecord::RecordNotUnique
    repuesto.errors.add(:nombre, :taken)
    raise ActiveRecord::RecordInvalid, repuesto
  end
end
