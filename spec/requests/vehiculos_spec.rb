require "rails_helper"

RSpec.describe "Vehiculos", type: :request do
  let!(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:cliente) { create(:cliente, nombre: "Ana Gómez") }

  describe "POST /vehiculos" do
    let(:params) do
      { vehiculo: { cliente_id: cliente.id, patente: "ab 123 cd", marca: "Fiat", modelo: "Cronos",
                    anio: 2021, kilometraje: 30_000 } }
    end

    it "permite al administrador registrar un vehículo de un cliente" do
      expect {
        post "/vehiculos", params: params, headers: auth_headers(admin), as: :json
      }.to change(Vehiculo, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "patente" => "AB123CD", "marca" => "Fiat", "modelo" => "Cronos", "anio" => 2021, "kilometraje" => 30_000
      )
      expect(response.parsed_body["cliente"]).to include("id" => cliente.id, "nombre" => "Ana Gómez")
    end

    it "permite registrar un vehículo solo con la patente" do
      post "/vehiculos", params: { vehiculo: { cliente_id: cliente.id, patente: "AB123CD" } },
                         headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("marca" => nil, "anio" => nil, "kilometraje" => nil)
    end

    it "exige la patente" do
      post "/vehiculos", params: { vehiculo: params[:vehiculo].except(:patente) },
                         headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["patente"]).to include("Patente no puede estar en blanco")
    end

    it "exige el cliente" do
      post "/vehiculos", params: { vehiculo: params[:vehiculo].except(:cliente_id) },
                         headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["cliente"]).to include("Dueño debe existir")
    end

    it "rechaza una patente ya registrada a otro cliente" do
      create(:vehiculo, patente: "AB123CD")

      expect {
        post "/vehiculos", params: params, headers: auth_headers(admin), as: :json
      }.not_to change(Vehiculo, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["patente"]).to include("Patente ya está en uso")
    end

    it "prohíbe a un mecánico registrar vehículos" do
      post "/vehiculos", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      post "/vehiculos", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /vehiculos/:id/cambiar_duenio" do
    let(:vehiculo) { create(:vehiculo, cliente: cliente) }
    let(:nuevo_duenio) { create(:cliente, nombre: "Bruno Díaz") }

    it "cambia el dueño del vehículo" do
      patch "/vehiculos/#{vehiculo.id}/cambiar_duenio", params: { vehiculo: { cliente_id: nuevo_duenio.id } },
                                                        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["cliente"]).to include("id" => nuevo_duenio.id, "nombre" => "Bruno Díaz")
      expect(vehiculo.reload.cliente).to eq(nuevo_duenio)
    end

    it "rechaza asignarlo al mismo dueño" do
      patch "/vehiculos/#{vehiculo.id}/cambiar_duenio", params: { vehiculo: { cliente_id: cliente.id } },
                                                        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["cliente"]).to include("Dueño ya es el dueño de este vehículo")
    end

    it "rechaza un cliente inexistente" do
      patch "/vehiculos/#{vehiculo.id}/cambiar_duenio", params: { vehiculo: { cliente_id: 0 } },
                                                        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(vehiculo.reload.cliente).to eq(cliente)
    end

    it "exige el nuevo dueño" do
      patch "/vehiculos/#{vehiculo.id}/cambiar_duenio", params: { vehiculo: { patente: "ZZ999ZZ" } },
                                                        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it "devuelve 404 si el vehículo no existe" do
      patch "/vehiculos/0/cambiar_duenio", params: { vehiculo: { cliente_id: nuevo_duenio.id } },
                                           headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "prohíbe a un mecánico cambiar el dueño" do
      patch "/vehiculos/#{vehiculo.id}/cambiar_duenio", params: { vehiculo: { cliente_id: nuevo_duenio.id } },
                                                        headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /vehiculos" do
    it "lista los vehículos paginados por patente con su dueño" do
      %w[CC333CC AA111AA BB222BB].each { |patente| create(:vehiculo, patente: patente, cliente: cliente) }

      get "/vehiculos", params: { por_pagina: 2 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["vehiculos"].pluck("patente")).to eq(%w[AA111AA BB222BB])
      expect(response.parsed_body["vehiculos"].first["cliente"]["nombre"]).to eq("Ana Gómez")
      expect(response.parsed_body["meta"]).to include("total" => 3, "total_paginas" => 2)
    end

    it "filtra por cliente" do
      propio = create(:vehiculo, cliente: cliente)
      create(:vehiculo)

      get "/vehiculos", params: { cliente_id: cliente.id }, headers: auth_headers(admin)

      expect(response.parsed_body["vehiculos"].pluck("id")).to eq([ propio.id ])
    end

    it "prohíbe el listado a un mecánico" do
      get "/vehiculos", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
