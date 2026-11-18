class AseguradoraGuardar
  def self.call(aseguradora: Aseguradora.new, **atributos)
    aseguradora.assign_attributes(atributos)
    aseguradora.telegram_chat_id = nil if aseguradora.telefono_changed?
    aseguradora.save!
    aseguradora
  rescue ActiveRecord::RecordNotUnique
    aseguradora.errors.add(:nombre, :taken)
    raise ActiveRecord::RecordInvalid, aseguradora
  end
end
