class RepuestoAdjuntarComprobante
  TIPOS_PERMITIDOS = %w[image/jpeg image/png image/webp].freeze
  TAMANO_MAXIMO = 8.megabytes

  class << self
    def call(repuesto:, archivo:)
      repuesto.orden.with_lock do
        repuesto.lock!
        validar_contexto(repuesto)
        tipo = validar_archivo(repuesto, archivo)
        raise ActiveRecord::RecordInvalid, repuesto if repuesto.errors.any?

        repuesto.comprobante.attach(io: archivo, filename: nombre(archivo), content_type: tipo)
        repuesto
      end
    end

    private

    def validar_contexto(repuesto)
      repuesto.errors.add(:orden, repuesto.orden.estado.to_sym) unless repuesto.orden.abierta?
      repuesto.errors.add(:estado, :ya_quitado) if repuesto.quitado_en.present?
    end

    def validar_archivo(repuesto, archivo)
      unless archivo_subido?(archivo)
        repuesto.errors.add(:comprobante, :en_blanco)
        return
      end

      if archivo.size.to_i <= 0
        repuesto.errors.add(:comprobante, :en_blanco)
        return
      end

      if archivo.size > TAMANO_MAXIMO
        repuesto.errors.add(:comprobante, :demasiado_grande)
        return
      end

      tipo = tipo_real(archivo)
      repuesto.errors.add(:comprobante, :tipo_invalido) unless TIPOS_PERMITIDOS.include?(tipo)
      tipo
    end

    def archivo_subido?(archivo)
      archivo.respond_to?(:read) && archivo.respond_to?(:size) && archivo.respond_to?(:rewind)
    end

    def tipo_real(archivo)
      tipo = Marcel::MimeType.for(archivo)
      archivo.rewind
      tipo
    end

    def nombre(archivo)
      nombre = archivo.original_filename if archivo.respond_to?(:original_filename)
      nombre.presence || "comprobante"
    end
  end
end
