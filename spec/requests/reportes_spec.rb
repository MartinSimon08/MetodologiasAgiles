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

  describe "GET /reportes/margen_repuestos" do
    it "muestra el margen total de los repuestos de las órdenes del período" do
      orden = travel_to(Time.zone.local(2026, 4, 10, 12)) { create(:orden) }
      RepuestoAgregar.call(
        orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1,
        costo_unitario: "100", margen: "25"
      )

      get "/reportes/margen_repuestos", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("margen_total" => "25.0")
    end

    it "devuelve cero cuando el período no tiene repuestos que sumen margen" do
      get "/reportes/margen_repuestos", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("margen_total" => "0.0")
    end

    it "devuelve errores de campo para un período inválido o incompleto" do
      get "/reportes/margen_repuestos", params: { hasta: "2026-04-30" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to eq("desde" => [ "no puede estar en blanco" ])
    end

    it "exige autenticación" do
      get "/reportes/margen_repuestos", params: { desde: "2026-04-01", hasta: "2026-04-30" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a los mecánicos consultar el reporte" do
      get "/reportes/margen_repuestos", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end

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

  describe "GET /reportes/ordenes_por_periodo" do
    it "cuenta las órdenes abiertas y cerradas en el período" do
      travel_to(Time.zone.local(2026, 4, 10, 12)) { create(:orden) }
      cerrada = travel_to(Time.zone.local(2026, 4, 12, 12)) { create(:orden) }
      cerrada.update!(estado: :cerrada, cerrada_en: Time.zone.local(2026, 4, 20, 12), cerrada_por: admin, total_cerrado: 0)

      get "/reportes/ordenes_por_periodo", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("abiertas" => 2, "cerradas" => 1)
    end

    it "devuelve cero cuando el período no tiene órdenes" do
      get "/reportes/ordenes_por_periodo", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("abiertas" => 0, "cerradas" => 0)
    end

    it "devuelve errores de campo para un período inválido o incompleto" do
      get "/reportes/ordenes_por_periodo", params: { hasta: "2026-04-30" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to eq("desde" => [ "no puede estar en blanco" ])
    end

    it "exige autenticación" do
      get "/reportes/ordenes_por_periodo", params: { desde: "2026-04-01", hasta: "2026-04-30" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a los mecánicos consultar el reporte" do
      get "/reportes/ordenes_por_periodo", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end
end
