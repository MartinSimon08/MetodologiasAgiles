require "rails_helper"

RSpec.describe "Turnera", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:lunes) { Date.new(2026, 11, 9) }

  describe "GET /turnera" do
    it "devuelve la semana con los turnos de cada día, su estado y el cupo diario" do
      ConfiguracionTaller.actual.update!(cupo_diario: 1)
      aseguradora = create(:aseguradora, nombre: "Sancor")
      asegurado = create(:cliente, nombre: "Ana Pérez")
      vehiculo = create(:vehiculo, cliente: asegurado, patente: "AB123CD")
      caso = create(:caso, aseguradora: aseguradora, asegurado: asegurado, vehiculo: vehiculo,
                           numero_siniestro: "SIN-1", fecha_turno: lunes)
      create(:caso, fecha_turno: lunes)

      get "/turnera", params: { fecha: "2026-11-12" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      cuerpo = response.parsed_body
      expect(cuerpo).to include("desde" => "2026-11-09", "hasta" => "2026-11-15", "cupo_diario" => 1)
      expect(cuerpo["dias"].map { |dia| dia["fecha"] }).to eq((lunes..lunes + 6.days).map(&:iso8601))
      expect(cuerpo["dias"].first).to include("fecha" => "2026-11-09", "ingresos" => 2, "supera_cupo" => true)
      expect(cuerpo["dias"].first["turnos"].first).to eq(
        "caso_id" => caso.id, "numero_siniestro" => "SIN-1", "estado" => "turno_asignado", "orden_id" => nil,
        "aseguradora" => { "id" => aseguradora.id, "nombre" => "Sancor" },
        "asegurado" => { "id" => asegurado.id, "nombre" => "Ana Pérez", "telefono" => asegurado.telefono },
        "vehiculo" => { "id" => vehiculo.id, "patente" => "AB123CD", "marca" => vehiculo.marca, "modelo" => vehiculo.modelo }
      )
      expect(cuerpo["dias"].second).to include("ingresos" => 0, "supera_cupo" => false, "turnos" => [])
    end

    it "devuelve errores de campo para una fecha inválida" do
      get "/turnera", params: { fecha: "no-es-fecha" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to eq("fecha" => [ "no es una fecha válida" ])
    end

    it "exige autenticación" do
      get "/turnera"

      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a los mecánicos ver la turnera" do
      get "/turnera", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
