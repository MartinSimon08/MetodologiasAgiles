class OrdenCorregir
  CAMPOS = CorreccionOrden::CAMPOS.map(&:to_sym).freeze
  TOTAL_MAXIMO = 10_000_000_000_000

  def self.call(orden:, usuario:, motivo:, confirmar_revision: false, **cambios)
    orden.with_lock do
      orden.errors.add(:base, :no_corregible) unless orden.cerrada?
      orden.errors.add(:base, :sin_cambios) if cambios.slice(*CAMPOS).empty?
      raise ActiveRecord::RecordInvalid, orden if orden.errors.any?

      anteriores = orden.slice(*CAMPOS)
      cambios.slice(*CAMPOS).each { |campo, valor| asignar(orden, campo, valor) }
      cambiados = CAMPOS.select { |campo| orden.public_send(campo) != anteriores[campo.to_s] }
      validar(orden, motivo, cambiados, confirmar_revision)

      correcciones = cambiados.map do |campo|
        CorreccionOrden.new(orden: orden, usuario: usuario, campo: campo, motivo: motivo,
                            valor_anterior: anteriores[campo.to_s], valor_nuevo: orden.public_send(campo),
                            revision_confirmada: revision_requerida?(orden))
      end
      orden.save!
      correcciones.each(&:save!)
      orden
    end
  end

  def self.revision_requerida?(orden)
    orden.franquicia_was.present? || orden.caso.present?
  end

  def self.asignar(orden, campo, valor)
    return orden.public_send("#{campo}=", nil) if campo == :franquicia && valor.blank?

    decimal = BigDecimal(valor.to_s, exception: false)
    if decimal.nil? || !decimal.finite? || decimal.abs >= TOTAL_MAXIMO
      orden.errors.add(campo, :not_a_number)
    else
      orden.public_send("#{campo}=", decimal)
    end
  end

  def self.validar(orden, motivo, cambiados, confirmar_revision)
    correccion = CorreccionOrden.new(motivo: motivo, campo: CAMPOS.first.to_s)
    correccion.validate
    correccion.errors[:motivo].each { |mensaje| orden.errors.add(:motivo_correccion, mensaje) }
    orden.errors.add(:base, :sin_cambios) if orden.errors.empty? && cambiados.empty?
    orden.errors.add(:total_cerrado, :menor_a_adelantos) if total_bajo_adelantos?(orden)
    orden.errors.add(:base, :revision_requerida) if cambiados.any? && revision_requerida?(orden) && !confirmar_revision
    raise ActiveRecord::RecordInvalid, orden if orden.errors.any? || !orden.valid?
  end

  def self.total_bajo_adelantos?(orden)
    orden.total_cerrado.present? && orden.total_cerrado < orden.adelantos.sum(:importe).to_d
  end

  private_class_method :asignar, :validar, :total_bajo_adelantos?
end
