require "base64"
require "digest"
require "uri"

module Oauth
  class Autorizar
    CAMPOS = %w[response_type client_id redirect_uri code_challenge code_challenge_method state resource scope].freeze
    DESCRIPCIONES = {
      "unsupported_response_type" => "Solo se admite response_type=code.",
      "invalid_request" => "La solicitud está incompleta.",
      "invalid_target" => "El recurso no coincide con este taller.",
      "invalid_scope" => "El alcance pedido no está disponible."
    }.freeze

    Resultado = Data.define(:redireccion, :html, :estado)

    def self.formulario(params:, recurso:, accion:)
      new(params, recurso, accion).formulario
    end

    def self.conceder(params:, recurso:, accion:)
      new(params, recurso, accion).conceder
    end

    def initialize(params, recurso, accion)
      @params = params.to_h.stringify_keys
      @recurso = recurso
      @accion = accion
    end

    def formulario
      cliente = cliente_confiable
      return cliente if cliente.is_a?(Resultado)

      error = error_protocolo
      return redirigir_error(cliente, error) if error

      pagina(cliente)
    end

    def conceder
      cliente = cliente_confiable
      return cliente if cliente.is_a?(Resultado)

      error = error_protocolo
      return redirigir_error(cliente, error) if error

      token = UsuarioAutenticar.call(email: @params["email"], password: @params["password"])
      return pagina(cliente, "Email o contraseña incorrectos", :unprocessable_content) unless token

      usuario = Usuario.activos.find_by(id: JsonWebToken.decode(token)&.dig("usuario_id"))
      return pagina(cliente, "Email o contraseña incorrectos", :unprocessable_content) unless usuario
      crudo = SecureRandom.urlsafe_base64(32)
      OauthCodigo.create!(
        digesto: Digesto.de(crudo),
        usuario: usuario,
        client_id: cliente.client_id,
        redirect_uri: @params["redirect_uri"],
        code_challenge: desafio,
        recurso: @recurso.mcp,
        scope: AccessToken::SCOPE,
        expira_en: OauthCodigo::TTL.from_now
      )
      query = { code: crudo }
      query[:state] = @params["state"] if @params["state"].present?
      Resultado.new(con_query(@params["redirect_uri"], query), nil, :found)
    end

    private

    def cliente_confiable
      cliente = ClienteResolver.call(@params["client_id"])
      unless cliente
        return Resultado.new(nil, Formulario.error("Cliente desconocido."), :bad_request)
      end
      unless ClienteResolver.acepta?(cliente, @params["redirect_uri"].to_s)
        return Resultado.new(nil, Formulario.error("La dirección de retorno no está registrada."), :bad_request)
      end

      cliente
    end

    def error_protocolo
      return "unsupported_response_type" unless @params["response_type"] == "code"
      return "invalid_request" unless desafio.match?(/\A[A-Za-z0-9\-_]{43,128}\z/)
      return "invalid_request" unless @params["code_challenge_method"] == "S256"
      return "invalid_request" unless state_valido?
      return "invalid_target" unless Recurso.iguales?(Recurso.canonico(@params["resource"]), @recurso.mcp)
      return "invalid_scope" unless scope_valido?

      nil
    end

    def desafio
      @params["code_challenge"].to_s.delete("=")
    end

    def state_valido?
      estado = @params["state"]
      return true if estado.nil? || estado == ""

      estado.is_a?(String) && estado.match?(/\A[\x20-\x7E]{1,512}\z/)
    end

    def scope_valido?
      texto = @params["scope"].to_s
      texto.blank? || texto.split.all? { |parte| parte == AccessToken::SCOPE }
    end

    def redirigir_error(cliente, codigo)
      query = { error: codigo, error_description: DESCRIPCIONES.fetch(codigo) }
      query[:state] = @params["state"] if @params["state"].present? && state_valido?
      Resultado.new(con_query(cliente.redirect_uris.find { |uri| uri == @params["redirect_uri"] }, query), nil, :found)
    end

    def pagina(cliente, error = nil, estado = :ok)
      Resultado.new(nil, Formulario.acceso(
        accion: @accion, cliente: cliente, redirect_uri: @params["redirect_uri"], campos: campos, error: error
      ), estado)
    end

    def campos
      CAMPOS.index_with { |clave| @params[clave].to_s }
    end

    def con_query(uri, query)
      destino = URI.parse(uri)
      destino.query = URI.encode_www_form(query)
      destino.to_s
    end
  end
end
