require "rails_helper"

RSpec.describe "Ordenes", type: :request do
  let!(:mecanico) { create(:usuario) }

  describe "GET /ordenes" do
    it "lista las órdenes para un usuario autenticado" do
      create(:orden, cliente: "Carla Gómez")
      create(:orden, :cerrada, cliente: "Bruno Díaz")

      get "/ordenes", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["ordenes"].pluck("cliente")).to contain_exactly("Carla Gómez", "Bruno Díaz")
    end

    it "exige autenticación" do
      get "/ordenes"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /ordenes/:id" do
    it "devuelve los datos de la orden" do
      orden = create(:orden, cliente: "Carla Gómez", vehiculo: "Fiat Cronos ABC123")

      get "/ordenes/#{orden.id}", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("cliente" => "Carla Gómez", "vehiculo" => "Fiat Cronos ABC123", "estado" => "abierta")
    end

    it "devuelve 404 si la orden no existe" do
      get "/ordenes/0", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:not_found)
    end
  end
end
