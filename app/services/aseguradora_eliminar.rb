class AseguradoraEliminar
  def self.call(aseguradora:)
    aseguradora.with_lock do
      raise ActiveRecord::RecordInvalid, aseguradora unless aseguradora.destroy
    end
  end
end
