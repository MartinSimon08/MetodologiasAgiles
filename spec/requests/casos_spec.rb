require "rails_helper"

RSpec.describe "Casos de siniestro", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:aseguradora) { create(:aseguradora, nombre: "Sancor") }
  let(:asegurado) { create(:cliente, nombre: "Ana Pérez") }
  let(:vehiculo) { create(:vehiculo, cliente: asegurado, patente: "AB123CD") }
  let(:datos) do
    { aseguradora_id: aseguradora.id, asegurado_id: asegurado.id, vehiculo_id: vehiculo.id, numero_siniestro: "sin-0001" }
  end

  describe "POST /casos" do
    it "abre un caso asociado a aseguradora, asegurado y vehículo, sin turno ni orden" do
      post "/casos", params: { caso: datos.merge(descripcion: "Choque trasero") }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "id" => Caso.last.id, "numero_siniestro" => "SIN-0001", "descripcion" => "Choque trasero",
        "fecha_turno" => nil, "orden_id" => nil,
        "aseguradora" => { "id" => aseguradora.id, "nombre" => "Sancor" },
        "asegurado" => a_hash_including("id" => asegurado.id, "nombre" => "Ana Pérez"),
        "vehiculo" => a_hash_including("id" => vehiculo.id, "patente" => "AB123CD")
      )
    end

    it "ignora turno y orden enviados al abrir" do
      orden = create(:orden, vehiculo: vehiculo, cliente: asegurado)

      post "/casos", params: { caso: datos.merge(fecha_turno: Date.current, orden_id: orden.id) }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(Caso.last).to have_attributes(fecha_turno: nil, orden_id: nil)
    end

    %i[aseguradora_id asegurado_id vehiculo_id numero_siniestro].each do |campo|
      it "exige #{campo}" do
        expect {
          post "/casos", params: { caso: datos.except(campo) }, headers: auth_headers(admin), as: :json
        }.not_to change(Caso, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to have_key(campo.to_s.delete_suffix("_id"))
      end
    end

    it "rechaza repetir el número de siniestro en la misma aseguradora" do
      create(:caso, aseguradora: aseguradora, numero_siniestro: "SIN-0001")

      expect {
        post "/casos", params: { caso: datos.merge(numero_siniestro: " Sin-0001 ") }, headers: auth_headers(admin), as: :json
      }.not_to change(Caso, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["numero_siniestro"]).to eq([ "Número de siniestro ya está cargado para esta aseguradora" ])
    end

    it "permite el mismo número de siniestro en otra aseguradora" do
      create(:caso, numero_siniestro: "SIN-0001")

      post "/casos", params: { caso: datos }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
    end

    it "rechaza un vehículo que no es del asegurado" do
      post "/casos", params: { caso: datos.merge(vehiculo_id: create(:vehiculo).id) }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["vehiculo"]).to eq([ "Vehículo no pertenece al asegurado" ])
    end

    it "rechaza una aseguradora desactivada" do
      aseguradora.update!(activa: false)

      post "/casos", params: { caso: datos }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["aseguradora"]).to eq([ "Aseguradora está desactivada" ])
    end

    it "prohíbe a mecánicos abrir casos" do
      expect {
        post "/casos", params: { caso: datos }, headers: auth_headers(create(:usuario)), as: :json
      }.not_to change(Caso, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /casos" do
    it "lista los casos del más nuevo al más viejo" do
      viejo = create(:caso, created_at: 2.days.ago)
      nuevo = create(:caso)

      get "/casos", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["casos"].pluck("id")).to eq([ nuevo.id, viejo.id ])
      expect(response.parsed_body["meta"]).to include("total" => 2)
    end

    it "busca por número de siniestro, patente, asegurado o aseguradora" do
      caso = create(:caso, aseguradora: aseguradora, asegurado: asegurado, vehiculo: vehiculo, numero_siniestro: "SIN-0001")
      create(:caso)

      [ "sin-0001", "ab123", "pérez", "sanc" ].each do |termino|
        get "/casos", params: { buscar: termino }, headers: auth_headers(admin)

        expect(response.parsed_body["casos"].pluck("id")).to eq([ caso.id ]), "falló con #{termino}"
      end
    end
  end
end
