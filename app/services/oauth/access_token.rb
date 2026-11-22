module Oauth
  class AccessToken
    TTL = 15.minutes
    SCOPE = "taller"
    USO = "mcp"

    def self.emitir(usuario:, recurso:, client_id:)
      JsonWebToken.encode(
        {
          uso: USO,
          usuario_id: usuario.id,
          aud: recurso.mcp,
          iss: recurso.emisor,
          client_id: client_id,
          scope: SCOPE
        },
        exp: TTL.from_now
      )
    end

    def self.usuario(token, recurso:)
      payload = JsonWebToken.decode(token)
      return unless payload
      return unless payload["uso"] == USO
      return unless Recurso.iguales?(payload["iss"].to_s, recurso.emisor)
      return unless audiencia_valida?(payload["aud"], recurso.mcp)
      return unless payload["scope"].to_s.split.include?(SCOPE)

      Usuario.activos.find_by(id: payload["usuario_id"])
    end

    def self.audiencia_valida?(aud, esperado)
      valor = aud.is_a?(Array) ? (aud.one? ? aud.first : nil) : aud
      Recurso.iguales?(valor.to_s, esperado)
    end

    private_class_method :audiencia_valida?
  end
end
