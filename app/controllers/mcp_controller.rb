class McpController < ApplicationController
  allow_unauthenticated_access

  def show
    responder_sin_cuerpo
  end

  def destroy
    responder_sin_cuerpo
  end

  def create
    return rechazar_origen unless origen_permitido?
    return no_autenticado unless (usuario = usuario_actual)
    return head :not_acceptable unless acepta_respuesta?

    version = request.headers["MCP-Protocol-Version"]
    if version.present? && Mcp::Servidor::VERSIONES.exclude?(version)
      return render json: rpc(-32600, "Versión de protocolo no soportada"), status: :bad_request
    end

    cuerpo = request.raw_post.to_s
    return head :payload_too_large if cuerpo.bytesize > 65_536

    respuesta = Mcp::Servidor.call(mensaje: JSON.parse(cuerpo), usuario: usuario)
    response.set_header("MCP-Protocol-Version", version.presence || Mcp::Servidor::VERSION)
    if respuesta.estado == 202
      head :accepted
    else
      render json: respuesta.cuerpo, status: respuesta.estado
    end
  rescue JSON::ParserError
    render json: rpc(-32700, "JSON inválido"), status: :bad_request
  end

  private

  def responder_sin_cuerpo
    return rechazar_origen unless origen_permitido?
    return no_autenticado unless usuario_actual

    response.set_header("Allow", "POST")
    head :method_not_allowed
  end

  def usuario_actual
    token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
    return if token.blank?

    Oauth::AccessToken.usuario(token, recurso: Oauth::Recurso.desde(request))
  end

  def origen_permitido?
    origen = request.headers["Origin"].to_s
    return true if origen.blank?

    uri = URI.parse(origen)
    return false unless uri.is_a?(URI::HTTP) && uri.host.present?

    host = uri.host.downcase
    host == request.host.downcase || Oauth::RedirectUri.loopback?(host)
  rescue URI::InvalidURIError
    false
  end

  def acepta_respuesta?
    accept = request.headers["Accept"].to_s
    accept.blank? || accept.include?("application/json") || accept.include?("*/*") || accept.include?("text/event-stream")
  end

  def no_autenticado
    metadata = "#{Oauth::Recurso.desde(request).emisor}/.well-known/oauth-protected-resource"
    detalle = request.authorization.present? ? 'error="invalid_token", ' : ""
    response.set_header(
      "WWW-Authenticate",
      %(Bearer #{detalle}resource_metadata="#{metadata}", scope="#{Oauth::AccessToken::SCOPE}")
    )
    head :unauthorized
  end

  def rechazar_origen
    render json: rpc(-32600, "Origen no permitido"), status: :forbidden
  end

  def rpc(codigo, mensaje)
    { jsonrpc: "2.0", id: nil, error: { code: codigo, message: mensaje } }
  end
end
