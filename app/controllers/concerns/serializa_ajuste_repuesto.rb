module SerializaAjusteRepuesto
  private

  def serialize_ajuste(ajuste)
    {
      id: ajuste.id,
      repuesto_id: ajuste.repuesto_id,
      tipo: ajuste.tipo,
      cantidad: ajuste.cantidad,
      costo_unitario: Dinero.importe(ajuste.costo_unitario),
      ajuste_costo: Dinero.importe(ajuste.ajuste_costo),
      ajuste_precio_cliente: Dinero.importe(ajuste.ajuste_precio_cliente),
      precio_original: Dinero.importe(ajuste.precio_original),
      motivo: ajuste.motivo,
      registrado_en: ajuste.registrado_en,
      created_at: ajuste.created_at,
      registrado_por: ajuste.registrado_por.as_json(only: %i[id nombre])
    }
  end
end
