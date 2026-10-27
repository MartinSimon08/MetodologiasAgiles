class AseguradoraCambiarEstado
  def self.call(aseguradora:, activa:)
    aseguradora.with_lock do
      if aseguradora.activa == activa
        aseguradora.errors.add(:base, activa ? :ya_activa : :ya_desactivada)
        raise ActiveRecord::RecordInvalid, aseguradora
      end

      aseguradora.update!(activa: activa)
    end
    aseguradora
  end
end
