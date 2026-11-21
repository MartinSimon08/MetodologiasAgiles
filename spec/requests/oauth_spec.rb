require "base64"
require "digest"
require "net/http"
require "rails_helper"
require "resolv"

RSpec.describe "OAuth del MCP", type: :request do
  let(:usuario) { create(:usuario, :administrador) }
  let(:recurso) { "http://www.example.com/mcp" }
  let(:redirect_uri) { "http://127.0.0.1:8787/callback" }

  def pkce
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    [ verifier, challenge ]
  end

  def autorizar(client_id: "taller-mcp", password: PasswordsDePrueba::VALIDA, **extra)
    _verifier, challenge = pkce
    parametros = {
      response_type: "code", client_id: client_id, redirect_uri: redirect_uri,
      code_challenge: challenge, code_challenge_method: "S256", resource: recurso
    }.merge(extra)
    post "/oauth/authorize", params: parametros.merge(email: usuario.email, password: password)
    [ parametros[:code_challenge], response ]
  end

  describe "descubrimiento" do
    it "publica el recurso protegido y el servidor de autorización" do
      get "/.well-known/oauth-protected-resource"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "resource" => recurso,
        "authorization_servers" => [ "http://www.example.com" ],
        "scopes_supported" => [ "taller" ]
      )

      get "/.well-known/oauth-authorization-server"

      expect(response.parsed_body).to include(
        "issuer" => "http://www.example.com",
        "authorization_endpoint" => "http://www.example.com/oauth/authorize",
        "token_endpoint" => "http://www.example.com/oauth/token",
        "registration_endpoint" => "http://www.example.com/oauth/registro",
        "code_challenge_methods_supported" => [ "S256" ],
        "client_id_metadata_document_supported" => true
      )
    end

    it "anuncia el prefijo /api cuando el frontend está montado" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("FRONTEND_DIST_PATH").and_return("dist")

      get "/.well-known/oauth-protected-resource/api/mcp"

      expect(response.parsed_body).to include(
        "resource" => "http://www.example.com/api/mcp",
        "authorization_servers" => [ "http://www.example.com/api" ]
      )
    end
  end

  describe "registro" do
    it "registra un cliente público con los retornos de Cursor" do
      post "/oauth/registro", params: {
        client_name: "Cursor",
        redirect_uris: [
          "http://127.0.0.1:8787/callback",
          "https://www.cursor.com/agents/mcp/oauth/callback",
          "cursor://anysphere.cursor-mcp/oauth/callback"
        ],
        grant_types: %w[authorization_code refresh_token],
        response_types: [ "code" ],
        token_endpoint_auth_method: "none"
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["client_id"]).to start_with("mcp_")
      expect(response.parsed_body["token_endpoint_auth_method"]).to eq("none")
    end

    it "rechaza un retorno hacia una red privada y un cliente confidencial" do
      post "/oauth/registro", params: {
        client_name: "Mal", redirect_uris: [ "https://10.0.0.1/callback" ]
      }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("invalid_redirect_uri")

      post "/oauth/registro", params: {
        client_name: "Mal", redirect_uris: [ redirect_uri ], token_endpoint_auth_method: "client_secret_basic"
      }, as: :json

      expect(response.parsed_body["error"]).to eq("invalid_client_metadata")
    end
  end

  describe "autorización" do
    it "muestra el cliente y el host de retorno, y escapa el nombre" do
      post "/oauth/registro", params: {
        client_name: "<script>", redirect_uris: [ redirect_uri ]
      }, as: :json
      client_id = response.parsed_body["client_id"]

      get "/oauth/authorize", params: {
        response_type: "code", client_id: client_id, redirect_uri: redirect_uri,
        code_challenge: pkce.last, code_challenge_method: "S256", resource: recurso
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("&lt;script&gt;")
      expect(response.body).to include("http://127.0.0.1")
      expect(response.body).not_to include("<script>")
    end

    it "no redirige si el cliente o el retorno no están registrados" do
      get "/oauth/authorize", params: { client_id: "otro", redirect_uri: "https://evil.test/cb" }

      expect(response).to have_http_status(:bad_request)
      expect(response.headers["Location"]).to be_nil
      expect(response.body).to include("Cliente desconocido")
    end

    it "vuelve al cliente con un código si la contraseña es correcta" do
      autorizar

      expect(response).to have_http_status(:found)
      query = Rack::Utils.parse_query(URI(response.headers["Location"]).query)
      expect(response.headers["Location"]).to start_with("#{redirect_uri}?")
      expect(query["code"]).to be_present
    end

    it "vuelve a pedir la contraseña si no coincide" do
      autorizar(password: PasswordsDePrueba::INCORRECTA)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Email o contraseña incorrectos")
      expect(OauthCodigo.count).to eq(0)
    end

    it "redirige con error si el recurso no es este taller" do
      autorizar(resource: "https://otro.test/mcp")

      query = Rack::Utils.parse_query(URI(response.headers["Location"]).query)
      expect(query["error"]).to eq("invalid_target")
      expect(query).not_to have_key("code")
    end
  end

  describe "tokens" do
    it "cambia el código por access y refresh, y rota el refresh" do
      verifier, challenge = pkce
      post "/oauth/authorize", params: {
        response_type: "code", client_id: "taller-mcp", redirect_uri: redirect_uri,
        code_challenge: challenge, code_challenge_method: "S256", resource: recurso,
        email: usuario.email, password: PasswordsDePrueba::VALIDA
      }
      code = Rack::Utils.parse_query(URI(response.headers["Location"]).query).fetch("code")

      post "/oauth/token", params: {
        grant_type: "authorization_code", code: code, redirect_uri: redirect_uri,
        client_id: "taller-mcp", code_verifier: verifier, resource: recurso
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("no-store")
      cuerpo = response.parsed_body
      expect(cuerpo["token_type"]).to eq("Bearer")
      expect(cuerpo["scope"]).to eq("taller")
      payload = JsonWebToken.decode(cuerpo["access_token"])
      expect(payload).to include("uso" => "mcp", "aud" => recurso, "usuario_id" => usuario.id)

      refresh = cuerpo["refresh_token"]
      post "/oauth/token", params: {
        grant_type: "refresh_token", refresh_token: refresh, client_id: "taller-mcp", resource: recurso
      }
      nuevo = response.parsed_body["refresh_token"]
      expect(nuevo).to be_present
      expect(nuevo).not_to eq(refresh)

      post "/oauth/token", params: {
        grant_type: "refresh_token", refresh_token: refresh, client_id: "taller-mcp", resource: recurso
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("invalid_grant")

      post "/oauth/token", params: {
        grant_type: "refresh_token", refresh_token: nuevo, client_id: "taller-mcp", resource: recurso
      }
      expect(response.parsed_body["error"]).to eq("invalid_grant")
    end

    it "invalida el código si el verificador PKCE no coincide" do
      verifier, challenge = pkce
      post "/oauth/authorize", params: {
        response_type: "code", client_id: "taller-mcp", redirect_uri: redirect_uri,
        code_challenge: challenge, code_challenge_method: "S256", resource: recurso,
        email: usuario.email, password: PasswordsDePrueba::VALIDA
      }
      code = Rack::Utils.parse_query(URI(response.headers["Location"]).query).fetch("code")

      post "/oauth/token", params: {
        grant_type: "authorization_code", code: code, redirect_uri: redirect_uri,
        client_id: "taller-mcp", code_verifier: "a" * 43, resource: recurso
      }

      expect(response.parsed_body["error"]).to eq("invalid_grant")

      post "/oauth/token", params: {
        grant_type: "authorization_code", code: code, redirect_uri: redirect_uri,
        client_id: "taller-mcp", code_verifier: verifier, resource: recurso
      }
      expect(response.parsed_body["error"]).to eq("invalid_grant")
    end
  end

  describe "metadata de cliente" do
    let(:url) { "https://app.example.com/oauth/client.json" }
    let(:documento) do
      {
        client_id: url,
        client_name: "Cliente externo",
        redirect_uris: [ redirect_uri ],
        token_endpoint_auth_method: "none"
      }
    end

    it "no pide el documento si el host resuelve a una red privada" do
      allow(Resolv).to receive(:getaddresses).with("app.example.com").and_return([ "10.0.0.8" ])
      expect(Net::HTTP).not_to receive(:new)

      get "/oauth/authorize", params: { client_id: url, redirect_uri: redirect_uri }

      expect(response.body).to include("Cliente desconocido")
    end

    it "acepta el documento si el host y los retornos son públicos" do
      allow(Resolv).to receive(:getaddresses).with("app.example.com").and_return([ "1.1.1.1" ])
      ok = Net::HTTPOK.new("1.1", "200", "OK")
      ok.instance_variable_set(:@read, true)
      ok.body = documento.to_json
      http = instance_double(Net::HTTP)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:verify_mode=)
      allow(http).to receive(:request).and_return(ok)
      allow(Net::HTTP).to receive(:new).with("app.example.com", 443).and_return(http)

      get "/oauth/authorize", params: {
        response_type: "code", client_id: url, redirect_uri: redirect_uri,
        code_challenge: pkce.last, code_challenge_method: "S256", resource: recurso
      }

      expect(response).to have_http_status(:ok), response.body
      expect(response.body).to include("Cliente externo")
    end
  end
end
