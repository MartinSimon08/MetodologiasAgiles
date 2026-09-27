require "rails_helper"

RSpec.describe "TareasFrecuentes", type: :request do
  let!(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  describe "POST /tareas_frecuentes" do
    let(:params) { { tarea_frecuente: { descripcion: "Cambio de aceite", precio_sugerido: "15000" } } }

    it "permite al administrador registrar una tarea frecuente" do
      expect {
        post "/tareas_frecuentes", params: params, headers: auth_headers(admin), as: :json
      }.to change(TareaFrecuente, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("descripcion" => "Cambio de aceite", "precio_sugerido" => "15000.0")
    end

    it "exige la descripción" do
      post "/tareas_frecuentes", params: { tarea_frecuente: { precio_sugerido: "15000" } },
                                 headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("descripcion")
    end

    it "exige un precio sugerido mayor a cero" do
      post "/tareas_frecuentes", params: { tarea_frecuente: params[:tarea_frecuente].merge(precio_sugerido: "0") },
                                 headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("precio_sugerido")
    end

    it "rechaza una descripción ya registrada" do
      create(:tarea_frecuente, descripcion: "Cambio de aceite")

      post "/tareas_frecuentes", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["descripcion"]).to include("Descripción ya está en uso")
    end

    it "prohíbe a un mecánico registrar tareas frecuentes" do
      post "/tareas_frecuentes", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      post "/tareas_frecuentes", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /tareas_frecuentes" do
    it "lista las tareas frecuentes ordenadas por descripción" do
      %w[Frenos Alineación Aceite].each { |descripcion| create(:tarea_frecuente, descripcion: descripcion) }

      get "/tareas_frecuentes", params: { por_pagina: 2 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tareas_frecuentes"].pluck("descripcion")).to eq(%w[Aceite Alineación])
    end

    it "permite a un mecánico consultar el catálogo para elegir una tarea al crearla" do
      create(:tarea_frecuente)

      get "/tareas_frecuentes", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
    end

    it "exige autenticación" do
      get "/tareas_frecuentes"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
