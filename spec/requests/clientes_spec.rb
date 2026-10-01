require "rails_helper"

RSpec.describe "Clientes", type: :request do
  let!(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  describe "POST /clientes" do
    let(:params) do
      { cliente: { nombre: "Ana Gómez", telefono: "11 4555-1234", email: "ana@correo.test" } }
    end

    it "permite al administrador registrar un cliente" do
      expect {
        post "/clientes", params: params, headers: auth_headers(admin), as: :json
      }.to change(Cliente, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "nombre" => "Ana Gómez", "telefono" => "1145551234", "email" => "ana@correo.test"
      )
    end

    it "permite registrar un cliente sin email" do
      post "/clientes", params: { cliente: params[:cliente].except(:email) }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["email"]).to be_nil
    end

    it "permite registrar un cliente sin vehículo" do
      post "/clientes", params: { cliente: params[:cliente].merge(vehiculo: { patente: "AB123CD" }) },
                        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).not_to have_key("vehiculo")
    end

    it "exige el teléfono" do
      post "/clientes", params: { cliente: { nombre: "Ana Gómez" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["telefono"]).to include("Teléfono no puede estar en blanco")
    end

    it "exige el nombre" do
      post "/clientes", params: { cliente: { telefono: "1145551234" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("nombre")
    end

    it "rechaza un teléfono ya registrado" do
      create(:cliente, telefono: "1145551234")

      expect {
        post "/clientes", params: params, headers: auth_headers(admin), as: :json
      }.not_to change(Cliente, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["telefono"]).to include("Teléfono ya está en uso")
    end

    it "rechaza un email inválido" do
      post "/clientes", params: { cliente: params[:cliente].merge(email: "ana") }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("email")
    end

    it "prohíbe a un mecánico registrar clientes" do
      post "/clientes", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      post "/clientes", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /clientes" do
    it "lista los clientes paginados y ordenados por nombre" do
      %w[Carla Ana Bruno].each { |nombre| create(:cliente, nombre: nombre) }

      get "/clientes", params: { por_pagina: 2 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["clientes"].pluck("nombre")).to eq(%w[Ana Bruno])
      expect(response.parsed_body["meta"]).to eq(
        "pagina" => 1, "por_pagina" => 2, "total" => 3, "total_paginas" => 2
      )
    end

    it "busca clientes por nombre, teléfono o patente" do
      ana = create(:cliente, nombre: "Ana Gómez", telefono: "1145551234")
      bruno = create(:cliente, nombre: "Bruno Díaz")
      create(:vehiculo, patente: "AB123CD", cliente: bruno)

      get "/clientes", params: { q: "gómez" }, headers: auth_headers(admin)
      expect(response.parsed_body["clientes"].pluck("id")).to eq([ ana.id ])

      get "/clientes", params: { q: "4555 1234" }, headers: auth_headers(admin)
      expect(response.parsed_body["clientes"].pluck("id")).to eq([ ana.id ])

      get "/clientes", params: { q: "ab-123-cd" }, headers: auth_headers(admin)
      expect(response.parsed_body["clientes"].pluck("id")).to eq([ bruno.id ])
      expect(response.parsed_body["meta"]).to include("total" => 1)
    end

    it "prohíbe el listado a un mecánico" do
      get "/clientes", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
