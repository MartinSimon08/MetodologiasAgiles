class RepuestoCatalogoEliminar
  def self.call(repuesto:)
    repuesto.with_lock do
      repuesto.destroy!
    end
  end
end
