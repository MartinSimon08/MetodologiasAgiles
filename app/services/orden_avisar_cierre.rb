class OrdenAvisarCierre
  DESTINOS = %w[aseguradora asegurado cliente_listo cliente_total].freeze

  def self.destinos(orden)
    caso = Caso.includes(:aseguradora, :asegurado).find_by(orden_id: orden.id)
    if caso
      [
        destino("aseguradora", "Avisar a la aseguradora del cierre", caso.aseguradora),
        destino("asegurado", "Avisar al asegurado que retire el vehículo", caso.asegurado)
      ]
    else
      [
        destino("cliente_listo", "Avisar al cliente que retire el vehículo", orden.cliente),
        destino("cliente_total", "Enviar el total al cliente", orden.cliente)
      ]
    end
  end

  def self.call(orden:, destino:, medio: "email")
    rechazar(orden, :no_cerrada) unless orden.cerrada?
    rechazar(orden, :destino_invalido) unless destinos(orden).any? { |d| d[:destino] == destino.to_s }

    caso = Caso.find_by(orden_id: orden.id)
    case destino.to_s
    when "aseguradora" then enviar(orden, medio, caso.aseguradora, aviso_aseguradora(orden, caso))
    when "asegurado" then CasoNotificarAsegurado.call(caso: caso)
    when "cliente_listo" then enviar(orden, medio, orden.cliente, aviso_cliente(orden, listo: true))
    when "cliente_total" then enviar(orden, medio, orden.cliente, aviso_cliente(orden, listo: false))
    end
    true
  end

  def self.destino(clave, etiqueta, contacto)
    { destino: clave, etiqueta: etiqueta, nombre: contacto.nombre, email: contacto.email,
      telegram_vinculada: contacto.telegram_vinculada? }
  end

  def self.rechazar(orden, motivo)
    orden.errors.add(:base, motivo)
    raise ActiveRecord::RecordInvalid, orden
  end

  def self.enviar(orden, medio, contacto, aviso)
    if medio.to_s == "telegram"
      rechazar(orden, :sin_telegram) unless contacto.telegram_vinculada?
      entregado = TelegramEnviar.call(texto: aviso[:texto], chat_ids: [ contacto.telegram_chat_id ])
    else
      rechazar(orden, :sin_email) if contacto.email.blank?
      entregado = EmailEnviar.call(destinatario: contacto.email, asunto: aviso[:asunto], texto: aviso[:texto],
                                   html: aviso[:html])
    end
    rechazar(orden, :envio_fallido) unless entregado
  end

  def self.aviso_aseguradora(orden, caso)
    comprobante = OrdenGenerarComprobante.call(orden: orden)
    titulo = "Orden ##{orden.id} cerrada"
    mensaje = "La reparación del siniestro #{caso.numero_siniestro} terminó y la orden quedó cerrada."
    texto = "#{mensaje}\nTotal a facturar a la aseguradora: $ #{comprobante.saldo_a_facturar.to_s('F')}"
    html = MailPlantilla.cierre(orden: orden, nombre: caso.aseguradora.nombre, titulo: titulo,
                                etiqueta: "Siniestro #{caso.numero_siniestro}", mensaje: mensaje,
                                monto: comprobante.saldo_a_facturar, rotulo_total: "Total a facturar")
    { asunto: "Orden ##{orden.id} cerrada - Siniestro #{caso.numero_siniestro}", texto: texto, html: html }
  end

  def self.aviso_cliente(orden, listo:)
    patente = orden.vehiculo.patente
    if listo
      titulo = "Tu vehículo está listo para retirar"
      mensaje = "Tu vehículo #{patente} ya está listo para retirar."
      total = nil
    else
      titulo = "Total de tu orden ##{orden.id}"
      mensaje = "La orden de tu vehículo #{patente} quedó cerrada. Este es el total del trabajo."
      total = OrdenGenerarComprobante.call(orden: orden).total
    end
    texto = total ? "#{mensaje}\nTotal: $ #{total.to_s('F')}" : mensaje
    html = MailPlantilla.cierre(orden: orden, nombre: orden.cliente.nombre, titulo: titulo,
                                etiqueta: "Orden ##{orden.id}", mensaje: mensaje, monto: total, rotulo_total: "Total")
    { asunto: "#{titulo} - Taller", texto: texto, html: html }
  end

  private_class_method :destino, :rechazar, :enviar, :aviso_aseguradora, :aviso_cliente
end
