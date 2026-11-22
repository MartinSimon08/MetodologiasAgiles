require "base64"
require "digest"
require "rails_helper"

RSpec.describe "Servidor MCP", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:recurso) { "http://www.example.com/mcp" }
  let(:redirect_uri) { "http://127.0.0.1:8787/callback" }

  def token_de(usuario)
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
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
    response.parsed_body.fetch("access_token")
  end

  def mcp(token, metodo, params = nil, id: 1, headers: {})
    cuerpo = { jsonrpc: "2.0", id: id, method: metodo }
    cuerpo[:params] = params if params
    post "/mcp", params: cuerpo, headers: {
      "Authorization" => "Bearer #{token}",
      "Accept" => "application/json, text/event-stream"
    }.merge(headers), as: :json
  end

  def herramienta(token, nombre, arguments = {})
    mcp(token, "tools/call", { name: nombre, arguments: arguments })
    JSON.parse(response.parsed_body.dig("result", "content", 0, "text"))
  end

  it "pide OAuth cuando no hay token de audiencia" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "initialize" },
      headers: auth_headers(admin), as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["WWW-Authenticate"]).to include(
      'resource_metadata="http://www.example.com/.well-known/oauth-protected-resource"'
    ).and include('scope="taller"')

    get "/ordenes", headers: { "Authorization" => "Bearer #{token_de(admin)}" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "rechaza un origen ajeno y una versión de protocolo desconocida" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "ping" },
      headers: { "Origin" => "https://evil.test", "Authorization" => "Bearer #{token_de(admin)}" }, as: :json

    expect(response).to have_http_status(:forbidden)

    mcp(token_de(admin), "ping", headers: { "MCP-Protocol-Version" => "1999-01-01" })
    expect(response).to have_http_status(:bad_request)
  end

  it "lista las herramientas y acepta la notificación de inicialización" do
    token = token_de(mecanico)
    mcp(token, "initialize", { protocolVersion: "2025-11-25", capabilities: {}, clientInfo: { name: "spec", version: "0" } })

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("result", "protocolVersion")).to eq("2025-11-25")
    expect(response.parsed_body.dig("result", "serverInfo", "name")).to eq("gestion-taller")

    post "/mcp", params: { jsonrpc: "2.0", method: "notifications/initialized" },
      headers: { "Authorization" => "Bearer #{token}", "Accept" => "application/json, text/event-stream" }, as: :json
    expect(response).to have_http_status(:accepted)
    expect(response.body).to be_empty

    mcp(token, "tools/list")
    nombres = response.parsed_body.dig("result", "tools").pluck("name")
    expect(nombres).to include("buscar_ordenes", "tomar_tarea", "cerrar_orden")
  end

  it "deja que el mecánico tome una tarea y le niega el cierre" do
    orden = create(:orden)
    tarea = create(:tarea, orden: orden)
    token = token_de(mecanico)

    cuerpo = herramienta(token, "tomar_tarea", { tarea_id: tarea.id })
    expect(cuerpo).to include("id" => tarea.id, "estado" => "en_curso")
    expect(tarea.reload).to be_en_curso

    mcp(token, "tools/call", { name: "cerrar_orden", arguments: { orden_id: orden.id } })
    expect(response.parsed_body.dig("result", "isError")).to be(true)
    expect(orden.reload).to be_abierta

    cuerpo = herramienta(token, "agregar_repuesto", { orden_id: orden.id, descripcion: "Filtro", cantidad: 1 })
    expect(cuerpo).to include("estado" => "pendiente_de_valorizar")
    expect(cuerpo.keys).not_to include("precio_cliente")
  end

  it "deja que recepción abra, presupueste y cierre" do
    vehiculo = create(:vehiculo)
    token = token_de(admin)
    abierta = herramienta(token, "abrir_orden", { patente: vehiculo.patente, motivo: "Service" })
    orden = Orden.find(abierta.fetch("id"))
    expect(orden).to be_abierta

    cargado = herramienta(token, "agregar_repuesto", {
      orden_id: orden.id, descripcion: "Filtro", cantidad: 2, costo_unitario: "100.00", margen: "20"
    })
    expect(cargado["precio_cliente"]).to eq("240.0")

    total = herramienta(token, "ver_total_parcial", { orden_id: orden.id })
    expect(total["total_repuestos"]).to eq("240.0")

    create(:tarea, orden: orden)
    mcp(token, "tools/call", { name: "cerrar_orden", arguments: { orden_id: orden.id } })
    expect(response.parsed_body.dig("result", "isError")).to be(true)

    cerrado = herramienta(token, "cerrar_orden", { orden_id: orden.id, descartar_pendientes: true })
    expect(cerrado).to include("estado" => "cerrada")
    expect(orden.reload).to be_cerrada
  end
end
