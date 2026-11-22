module Oauth
  class ClienteResolver
    FIJO_ID = "taller-mcp"
    REDIRECTS_FIJOS = [
      "http://localhost:8787/callback",
      "http://127.0.0.1:8787/callback",
      "https://www.cursor.com/agents/mcp/oauth/callback",
      RedirectUri::CURSOR,
      "https://claude.ai/api/mcp/auth_callback"
    ].freeze

    Cliente = Data.define(:client_id, :nombre, :redirect_uris)

    def self.call(client_id)
      id = client_id.to_s
      return fijo if id == FIJO_ID
      return ClienteMetadata.call(id) if id.start_with?("https://")

      registro = OauthCliente.find_by(client_id: id, origen: "registro")
      return unless registro

      Cliente.new(registro.client_id, registro.nombre, registro.redirect_uris)
    end

    def self.acepta?(cliente, uri)
      cliente.redirect_uris.any? { |registrada| registrada == uri }
    end

    def self.fijo
      extras = ENV.fetch("MCP_REDIRECT_URIS", "").split(",").filter_map { |uri|
        limpia = uri.strip
        limpia if RedirectUri.permitida?(limpia)
      }
      Cliente.new(FIJO_ID, "Cliente del taller", (REDIRECTS_FIJOS + extras).uniq)
    end

    private_class_method :fijo
  end
end
