class CasoAbrir
  def self.call(aseguradora_id:, asegurado_id:, vehiculo_id:, numero_siniestro:, descripcion: nil)
    caso = Caso.new(aseguradora_id: aseguradora_id, asegurado_id: asegurado_id, vehiculo_id: vehiculo_id,
                    numero_siniestro: numero_siniestro, descripcion: descripcion)
    caso.save!
    caso
  rescue ActiveRecord::RecordNotUnique
    caso.errors.add(:numero_siniestro, :taken)
    raise ActiveRecord::RecordInvalid, caso
  end
end
