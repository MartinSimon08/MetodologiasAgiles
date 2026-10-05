require "rails_helper"

RSpec.describe "Ordenes", type: :request do
  let!(:mecanico) { create(:usuario) }
  let!(:administrador) { create(:usuario, :administrador) }

  describe "GET /ordenes" do
    it "lista las órdenes para un usuario autenticado" do
      create(:orden, cliente: create(:cliente, nombre: "Carla Gómez"))
      create(:orden, :cerrada, cliente: create(:cliente, nombre: "Bruno Díaz"))

      get "/ordenes", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      nombres = response.parsed_body["ordenes"].map { |orden| orden["cliente"]["nombre"] }
      expect(nombres).to contain_exactly("Carla Gómez", "Bruno Díaz")
    end

    it "le devuelve las órdenes sin costos ni márgenes al mecánico" do
      create(:orden)

      get "/ordenes", headers: auth_headers(mecanico)

      expect(response.parsed_body["ordenes"].first.keys).to contain_exactly(
        "id", "motivo", "estado", "created_at", "cliente", "vehiculo"
      )
    end

    it "exige autenticación" do
      get "/ordenes"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /ordenes/:id" do
    it "devuelve los datos de la orden" do
      cliente = create(:cliente, nombre: "Carla Gómez")
      vehiculo = create(:vehiculo, cliente: cliente, patente: "ABC123", marca: "Fiat", modelo: "Cronos", anio: 2021)
      orden = create(:orden, vehiculo: vehiculo, motivo: "Ruido al frenar")

      get "/ordenes/#{orden.id}", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("motivo" => "Ruido al frenar", "estado" => "abierta")
      expect(response.parsed_body["cliente"]).to include("id" => cliente.id, "nombre" => "Carla Gómez")
      expect(response.parsed_body["vehiculo"]).to eq(
        "id" => vehiculo.id, "patente" => "ABC123", "marca" => "Fiat", "modelo" => "Cronos", "anio" => 2021
      )
    end

    it "le devuelve la orden sin costos ni márgenes al mecánico" do
      orden = create(:orden)
      create(:tarea, orden: orden, precio: 15_000)

      get "/ordenes/#{orden.id}", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.keys).to contain_exactly("id", "motivo", "estado", "created_at", "cliente", "vehiculo")
    end

    it "devuelve 404 si la orden no existe" do
      get "/ordenes/0", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /ordenes" do
    let(:vehiculo) { create(:vehiculo, patente: "AB123CD") }
    let(:params) { { orden: { vehiculo_id: vehiculo.id, motivo: "Ruido al frenar" } } }

    it "abre una orden asociada al vehículo y a su dueño" do
      freeze_time do
        expect {
          post "/ordenes", params: params, headers: auth_headers(administrador)
        }.to change(Orden, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to include("motivo" => "Ruido al frenar", "estado" => "abierta")
        expect(Time.zone.parse(response.parsed_body["created_at"])).to eq(Time.current)
        expect(response.parsed_body["vehiculo"]).to include("id" => vehiculo.id, "patente" => "AB123CD")
        expect(response.parsed_body["cliente"]).to include("id" => vehiculo.cliente.id)
      end
    end

    it "ignora un estado enviado por el cliente de la API" do
      post "/ordenes", params: { orden: params[:orden].merge(estado: "cerrada") }, headers: auth_headers(administrador)

      expect(response).to have_http_status(:created)
      expect(Orden.last).to be_abierta
    end

    it "rechaza un vehículo inexistente" do
      post "/ordenes", params: { orden: { vehiculo_id: 0, motivo: "Ruido al frenar" } },
                       headers: auth_headers(administrador)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["vehiculo"]).to include("Vehículo debe existir")
    end

    it "rechaza la orden sin motivo" do
      post "/ordenes", params: { orden: { vehiculo_id: vehiculo.id } }, headers: auth_headers(administrador)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["motivo"]).to include("Motivo de ingreso no puede estar en blanco")
    end

    it "rechaza abrir otra orden si el vehículo ya tiene una abierta" do
      create(:orden, vehiculo: vehiculo)

      expect {
        post "/ordenes", params: params, headers: auth_headers(administrador)
      }.not_to change(Orden, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["vehiculo"]).to include("Vehículo ya tiene una orden abierta")
    end

    it "permite abrir otra orden si la anterior del vehículo está cerrada" do
      create(:orden, :cerrada, vehiculo: vehiculo)

      post "/ordenes", params: params, headers: auth_headers(administrador)

      expect(response).to have_http_status(:created)
    end

    it "devuelve 400 si faltan los datos de la orden" do
      post "/ordenes", headers: auth_headers(administrador)

      expect(response).to have_http_status(:bad_request)
    end

    it "prohíbe abrir órdenes a un mecánico" do
      expect {
        post "/ordenes", params: params, headers: auth_headers(mecanico)
      }.not_to change(Orden, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      post "/ordenes", params: params

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
