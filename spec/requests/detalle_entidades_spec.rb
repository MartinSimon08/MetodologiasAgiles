require "rails_helper"

RSpec.describe "Detalle de cliente, aseguradora y caso", type: :request do
  let(:administrador) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:cliente) { create(:cliente) }
  let(:vehiculo) { create(:vehiculo, cliente: cliente) }
  let!(:caso) { create(:caso, asegurado: cliente, vehiculo: vehiculo) }

  it "muestra el cliente asegurado con sus vehículos, casos y órdenes" do
    orden = create(:orden, cliente: cliente, vehiculo: vehiculo)

    get "/clientes/#{cliente.id}", headers: auth_headers(administrador)

    expect(response).to have_http_status(:ok)
    cuerpo = response.parsed_body
    expect(cuerpo).to include("id" => cliente.id, "asegurado" => true)
    expect(cuerpo["vehiculos"].pluck("id")).to eq([ vehiculo.id ])
    expect(cuerpo["casos"].first).to include("id" => caso.id)
    expect(cuerpo["casos"].first["aseguradora"]).to include("id" => caso.aseguradora_id)
    expect(cuerpo["ordenes"].pluck("id")).to eq([ orden.id ])
  end

  it "marca como particular al cliente sin casos" do
    particular = create(:cliente)

    get "/clientes/#{particular.id}", headers: auth_headers(administrador)

    expect(response.parsed_body).to include("asegurado" => false, "casos" => [])
  end

  it "filtra los clientes por tipo" do
    particular = create(:cliente)

    get "/clientes", params: { tipo: "asegurado" }, headers: auth_headers(administrador)
    expect(response.parsed_body["clientes"].pluck("id")).to eq([ cliente.id ])
    expect(response.parsed_body["clientes"].first).to include("asegurado" => true)

    get "/clientes", params: { tipo: "particular" }, headers: auth_headers(administrador)
    expect(response.parsed_body["clientes"].pluck("id")).to eq([ particular.id ])
  end

  it "muestra la aseguradora con sus casos" do
    get "/aseguradoras/#{caso.aseguradora_id}", headers: auth_headers(administrador)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["casos"].first).to include("id" => caso.id)
    expect(response.parsed_body["casos"].first["asegurado"]).to include("id" => cliente.id)
  end

  it "muestra el caso con su orden y notificaciones" do
    orden = create(:orden, cliente: cliente, vehiculo: vehiculo)
    caso.update!(orden: orden)
    create(:notificacion_asegurado, caso: caso)

    get "/casos/#{caso.id}", headers: auth_headers(administrador)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["orden"]).to include("id" => orden.id)
    expect(response.parsed_body["notificaciones"].size).to eq(1)
  end

  it "avisa al asegurado con un mensaje propio aunque la orden esté cerrada" do
    orden = create(:orden, cliente: cliente, vehiculo: vehiculo, estado: :cerrada, cerrada_en: Time.current,
                           cerrada_por: administrador, total_cerrado: 0)
    caso.update!(orden: orden)

    expect {
      post "/casos/#{caso.id}/avisar", params: { mensaje: "Pasá a retirar el auto" },
           headers: auth_headers(administrador), as: :json
    }.to change(NotificacionAsegurado, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("contenido" => "Pasá a retirar el auto")
  end

  it "rechaza un aviso sin mensaje" do
    post "/casos/#{caso.id}/avisar", params: { mensaje: "  " }, headers: auth_headers(administrador), as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "responde 404 si no existe" do
    get "/casos/0", headers: auth_headers(administrador)

    expect(response).to have_http_status(:not_found)
  end

  it "prohíbe el detalle a un mecánico" do
    get "/clientes/#{cliente.id}", headers: auth_headers(mecanico)

    expect(response).to have_http_status(:forbidden)
  end
end
