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

  describe "GET /reportes/ingresos" do
    it "separa los ingresos cobrados del saldo pendiente de aseguradoras" do
      orden = create(:orden)
      create(:tarea, orden: orden, precio: 10_000)
      create(:caso, orden: orden, asegurado: orden.cliente, vehiculo: orden.vehiculo)
      travel_to(Time.zone.local(2026, 4, 10, 12)) do
        create(:adelanto, orden: orden, importe: "3000.00", registrado_por: admin)
      end
      travel_to(Time.zone.local(2026, 4, 15, 18)) do
        orden.update!(estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin, total_cerrado: orden.total)
      end

      directa = create(:orden)
      create(:tarea, orden: directa, precio: 5_000)
      travel_to(Time.zone.local(2026, 4, 12, 9)) do
        create(:adelanto, orden: directa, importe: "2000.00", registrado_por: admin)
      end

      get "/reportes/ingresos", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "franquicia_cobrada" => "3000.0",
        "saldo_facturado_aseguradoras" => "0.0",
        "saldo_pendiente_aseguradoras" => "7000.0",
        "ingresos_clientes_directos" => "2000.0",
        "total_ingresos" => "5000.0"
      )
    end

    it "devuelve ceros cuando el período no tiene ingresos" do
      get "/reportes/ingresos", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "franquicia_cobrada" => "0.0",
        "saldo_facturado_aseguradoras" => "0.0",
        "saldo_pendiente_aseguradoras" => "0.0",
        "ingresos_clientes_directos" => "0.0",
        "total_ingresos" => "0.0"
      )
    end

    it "devuelve errores de campo para un período inválido o incompleto" do
      get "/reportes/ingresos", params: { hasta: "2026-04-30" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to eq("desde" => [ "no puede estar en blanco" ])
    end

    it "exige autenticación" do
      get "/reportes/ingresos", params: { desde: "2026-04-01", hasta: "2026-04-30" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a los mecánicos consultar el reporte" do
      get "/reportes/ingresos", params: { desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end
end
