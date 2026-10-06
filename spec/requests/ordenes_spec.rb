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

    it "distingue las órdenes canceladas de las cerradas" do
      cancelada = create(:orden, :cancelada)
      cerrada = create(:orden, :cerrada)

      get "/ordenes", headers: auth_headers(mecanico)

      estados = response.parsed_body["ordenes"].to_h { |orden| [ orden["id"], orden["estado"] ] }
      expect(estados).to eq(cancelada.id => "cancelada", cerrada.id => "cerrada")
    end

    it "filtra las órdenes por estado" do
      create(:orden)
      create(:orden, :cerrada)
      cancelada = create(:orden, :cancelada)

      get "/ordenes", params: { estado: "cancelada" }, headers: auth_headers(administrador)

      expect(response.parsed_body["ordenes"].pluck("id")).to eq([ cancelada.id ])
      expect(response.parsed_body["meta"]["total"]).to eq(1)
    end

    it "ignora un estado desconocido en el filtro" do
      create(:orden)
      create(:orden, :cancelada)

      get "/ordenes", params: { estado: "pausada" }, headers: auth_headers(administrador)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["ordenes"].size).to eq(2)
    end

    it "le devuelve las órdenes sin costos ni márgenes al mecánico" do
      create(:orden)

      get "/ordenes", headers: auth_headers(mecanico)

      expect(response.parsed_body["ordenes"].first.keys).to contain_exactly(
        "id", "motivo", "estado", "created_at", "cancelada_en", "cliente", "vehiculo"
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
      expect(response.parsed_body.keys).to contain_exactly(
        "id", "motivo", "estado", "created_at", "cancelada_en", "cliente", "vehiculo"
      )
    end

    it "devuelve 404 si la orden no existe" do
      get "/ordenes/0", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /ordenes/:id/cancelar" do
    let!(:orden) { create(:orden, motivo: "Ruido al frenar") }

    it "permite al administrador cancelar una orden abierta" do
      freeze_time do
        patch "/ordenes/#{orden.id}/cancelar", headers: auth_headers(administrador)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("id" => orden.id, "estado" => "cancelada", "motivo" => "Ruido al frenar",
                                                "tareas_liberadas" => [])
        expect(Time.zone.parse(response.parsed_body["cancelada_en"])).to eq(Time.current)
        expect(orden.reload).to be_cancelada
      end
    end

    it "informa las tareas en curso que se liberaron" do
      tarea = create(:tarea, :en_curso, orden: orden, mecanico: mecanico, descripcion: "Cambiar pastillas")
      create(:tarea, :terminada, orden: orden, mecanico: mecanico)

      patch "/ordenes/#{orden.id}/cancelar", headers: auth_headers(administrador)

      expect(response.parsed_body["tareas_liberadas"]).to eq([ { "id" => tarea.id, "descripcion" => "Cambiar pastillas" } ])
      expect(tarea.reload).to be_pendiente
    end

    it "sigue mostrando la orden cancelada con sus datos y sus tareas" do
      tarea = create(:tarea, :terminada, orden: orden, mecanico: mecanico)
      patch "/ordenes/#{orden.id}/cancelar", headers: auth_headers(administrador)

      get "/ordenes/#{orden.id}", headers: auth_headers(administrador)
      expect(response.parsed_body).to include("estado" => "cancelada", "motivo" => "Ruido al frenar")
      expect(response.parsed_body["cancelada_en"]).to be_present
      expect(response.parsed_body["cliente"]).to include("id" => orden.cliente_id)

      get "/ordenes/#{orden.id}/tareas", headers: auth_headers(administrador)
      expect(response.parsed_body["tareas"].pluck("id", "estado")).to eq([ [ tarea.id, "terminada" ] ])
    end

    it "rechaza cancelar una orden ya cancelada" do
      patch "/ordenes/#{orden.id}/cancelar", headers: auth_headers(administrador)

      patch "/ordenes/#{orden.id}/cancelar", headers: auth_headers(administrador)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["base"]).to include("La orden ya está cancelada")
    end

    it "rechaza cancelar una orden cerrada" do
      orden.update!(estado: :cerrada)

      patch "/ordenes/#{orden.id}/cancelar", headers: auth_headers(administrador)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["base"]).to include("No se puede cancelar una orden cerrada")
      expect(orden.reload).to be_cerrada
    end

    it "prohíbe cancelar órdenes a un mecánico" do
      patch "/ordenes/#{orden.id}/cancelar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(orden.reload).to be_abierta
    end

    it "exige autenticación" do
      patch "/ordenes/#{orden.id}/cancelar"

      expect(response).to have_http_status(:unauthorized)
    end

    it "devuelve 404 si la orden no existe" do
      patch "/ordenes/0/cancelar", headers: auth_headers(administrador)

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

    it "permite abrir otra orden si la anterior del vehículo está cancelada" do
      create(:orden, :cancelada, vehiculo: vehiculo)

      post "/ordenes", params: params, headers: auth_headers(administrador)

      expect(response).to have_http_status(:created)
    end

    it "ignora una cancelación enviada por el cliente de la API" do
      post "/ordenes", params: { orden: params[:orden].merge(estado: "cancelada", cancelada_en: Time.current) },
                       headers: auth_headers(administrador)

      expect(response).to have_http_status(:created)
      expect(Orden.last).to have_attributes(estado: "abierta", cancelada_en: nil)
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
