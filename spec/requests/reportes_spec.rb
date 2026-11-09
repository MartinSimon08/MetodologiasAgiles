require "rails_helper"

RSpec.describe "Reportes", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  describe "GET /reportes/tareas_por_mecanico" do
    it "muestra las tareas tomadas y completadas por cada mecánico en el período" do
      otro = create(:usuario, nombre: "Beto")
      travel_to(Time.zone.local(2026, 4, 10, 12)) do
        create(:tarea, :terminada, mecanico: mecanico)
        create(:tarea, :en_curso, mecanico: otro)
      end

      get "/reportes/tareas_por_mecanico", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      cuerpo = response.parsed_body["mecanicos"]
      expect(cuerpo.find { |fila| fila["mecanico"]["id"] == mecanico.id })
        .to include("tomadas" => 1, "completadas" => 1)
      expect(cuerpo.find { |fila| fila["mecanico"]["id"] == otro.id })
        .to include("tomadas" => 1, "completadas" => 0)
    end

    it "muestra en 0 a un mecánico sin actividad en el período" do
      mecanico

      get "/reportes/tareas_por_mecanico", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["mecanicos"]).to contain_exactly(
        include("mecanico" => include("id" => mecanico.id), "tomadas" => 0, "completadas" => 0)
      )
    end

    it "devuelve errores de campo para un período inválido o incompleto" do
      get "/reportes/tareas_por_mecanico", params: { hasta: "2026-04-30" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to eq("desde" => [ "no puede estar en blanco" ])
    end

    it "exige autenticación" do
      get "/reportes/tareas_por_mecanico", params: { desde: "2026-04-01", hasta: "2026-04-30" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a los mecánicos consultar el reporte" do
      get "/reportes/tareas_por_mecanico", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end
end
