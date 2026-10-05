require "rails_helper"

RSpec.describe "Tareas del mecánico", type: :request do
  let!(:mecanico) { create(:usuario) }
  let!(:otro_mecanico) { create(:usuario) }
  let!(:vehiculo) { create(:vehiculo, patente: "AB123CD", marca: "Fiat", modelo: "Palio", anio: 2012) }
  let!(:orden) { create(:orden, vehiculo: vehiculo) }

  describe "GET /tareas_mecanico" do
    it "devuelve las tareas propias en curso y las disponibles de órdenes abiertas" do
      propia = create(:tarea, :en_curso, orden: orden, mecanico: mecanico)
      disponible = create(:tarea, orden: orden)
      create(:tarea, :en_curso, orden: orden, mecanico: otro_mecanico)
      create(:tarea, :terminada, orden: orden, mecanico: mecanico)
      create(:tarea, orden: create(:orden)).orden.update!(estado: :cerrada)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["mias"].pluck("id")).to eq([ propia.id ])
      expect(response.parsed_body["disponibles"].pluck("id")).to eq([ disponible.id ])
      expect(response.parsed_body["disponibles"].first["orden"]).to eq(
        "id" => orden.id,
        "vehiculo" => { "id" => vehiculo.id, "patente" => "AB123CD", "marca" => "Fiat", "modelo" => "Palio",
                        "anio" => 2012 },
        "cliente" => orden.cliente.nombre
      )
    end

    it "devuelve las tareas sin importes" do
      create(:tarea, :en_curso, orden: orden, mecanico: mecanico, precio: 15_000)
      create(:tarea, orden: orden, precio: 20_000)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      tareas = response.parsed_body.values_at("mias", "disponibles").flatten
      expect(tareas.size).to eq(2)
      expect(tareas.map(&:keys)).to all(
        contain_exactly("id", "orden_id", "descripcion", "estado", "mecanico_id", "tomada_en", "created_at", "orden")
      )
      expect(tareas.map { |tarea| tarea["orden"].keys }).to all(contain_exactly("id", "vehiculo", "cliente"))
    end

    it "prohíbe el acceso a un administrador" do
      get "/tareas_mecanico", headers: auth_headers(create(:usuario, :administrador))

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      get "/tareas_mecanico"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
