module Mcp
  class Servidor
    VERSIONES = %w[2025-03-26 2025-06-18 2025-11-25].freeze
    VERSION = "2025-11-25"
    INSTRUCCIONES = <<~TEXTO.squish
      Operás el día de un taller mecánico con el usuario que autorizó la sesión.
      La recepción abre órdenes, carga repuestos con costo y cierra. El mecánico toma, completa y libera tareas, y puede avisar un repuesto sin precio.
      Cerrar una orden registra el cobro: pedí confirmación antes de llamar a cerrar_orden.
    TEXTO

    Respuesta = Data.define(:estado, :cuerpo)

    def self.call(mensaje:, usuario:)
      new(mensaje, usuario).call
    end

    def initialize(mensaje, usuario)
      @mensaje = mensaje
      @usuario = usuario
      @id = nil
    end

    def call
      return rpc(-32600, "El mensaje tiene que ser un objeto JSON.") unless @mensaje.is_a?(Hash)
      return rpc(-32600, "jsonrpc tiene que ser 2.0.") unless @mensaje["jsonrpc"] == "2.0"

      metodo = @mensaje["method"]
      return rpc(-32600, "Falta method.") unless metodo.is_a?(String)
      return Respuesta.new(202, nil) if !@mensaje.key?("id") && metodo.start_with?("notifications/")
      return rpc(-32600, "La notificación no se acepta.") unless @mensaje.key?("id")

      @id = @mensaje["id"]
      return rpc(-32600, "id inválido.") unless @id.is_a?(String) || @id.is_a?(Integer) || @id.nil?

      params = @mensaje["params"] || {}
      return rpc(-32602, "params tiene que ser un objeto.") unless params.is_a?(Hash)

      Respuesta.new(200, { jsonrpc: "2.0", id: @id, result: despachar(metodo, params) })
    rescue Fallo => error
      case error.tipo
      when :parametros then rpc(-32602, error.message)
      when :metodo then rpc(-32601, error.message)
      else herramienta_error(error.message)
      end
    rescue ActiveRecord::RecordInvalid => error
      herramienta_error(error.record.errors.full_messages.join(" "))
    rescue ActiveRecord::RecordNotFound
      herramienta_error("No encontré ese registro.")
    end

    private

    def despachar(metodo, params)
      case metodo
      when "initialize" then inicializar(params)
      when "ping" then {}
      when "tools/list"
        raise Fallo.new(:parametros, "No hay más páginas.") if params["cursor"].present?

        { tools: Herramientas.definiciones }
      when "tools/call" then Herramientas.llamar(params["name"], params["arguments"] || {}, @usuario)
      else
        raise Fallo.new(:metodo, "Método no encontrado.")
      end
    end

    def inicializar(params)
      pedida = params["protocolVersion"].to_s
      {
        protocolVersion: VERSIONES.include?(pedida) ? pedida : VERSION,
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: "gestion-taller", version: "1.0.0" },
        instructions: INSTRUCCIONES
      }
    end

    def rpc(codigo, mensaje)
      Respuesta.new(codigo == -32600 ? 400 : 200, {
        jsonrpc: "2.0",
        id: @id,
        error: { code: codigo, message: mensaje }
      })
    end

    def herramienta_error(mensaje)
      Respuesta.new(200, {
        jsonrpc: "2.0",
        id: @id,
        result: { content: [ { type: "text", text: mensaje } ], isError: true }
      })
    end
  end
end
