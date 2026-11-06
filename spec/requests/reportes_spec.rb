require "rails_helper"

RSpec.describe "Reportes", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  describe "GET /reportes/tareas_frecuentes" do
    it "devuelve las tareas terminadas agrupadas por descripción, de más a menos frecuente" do
      create(:tarea, :terminada, descripcion: "Cambio de aceite")
      create(:tarea, :terminada, descripcion: "Cambio de aceite")
      create(:tarea, :terminada, descripcion: "Alineación")

      get "/reportes/tareas_frecuentes", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tareas"]).to eq([
        { "descripcion" => "Cambio de aceite", "cantidad" => 2 },
        { "descripcion" => "Alineación", "cantidad" => 1 }
      ])
    end

    it "devuelve una lista vacía cuando no hay tareas terminadas" do
      get "/reportes/tareas_frecuentes", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tareas"]).to eq([])
    end

    it "exige autenticación" do
      get "/reportes/tareas_frecuentes"

      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a los mecánicos consultar el reporte" do
      get "/reportes/tareas_frecuentes", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end
end
