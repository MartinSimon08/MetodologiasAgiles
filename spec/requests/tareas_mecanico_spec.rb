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
      marcar_cerrada(create(:tarea, orden: create(:orden)).orden)

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

    it "no ofrece tareas de órdenes canceladas" do
      create(:tarea, orden: orden)
      orden.update!(estado: :cancelada, cancelada_en: Time.current)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      expect(response.parsed_body).to eq("mias" => [], "disponibles" => [], "terminadas_hoy" => [])
    end

    it "devuelve las tareas sin importes" do
      create(:tarea, :en_curso, orden: orden, mecanico: mecanico, precio: 15_000)
      create(:tarea, orden: orden, precio: 20_000)
      create(:tarea, :terminada, orden: orden, mecanico: mecanico, precio: 10_000)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      tareas = response.parsed_body.values_at("mias", "disponibles", "terminadas_hoy").flatten
      expect(tareas.size).to eq(3)
      expect(tareas.map(&:keys)).to all(
        contain_exactly("id", "orden_id", "descripcion", "estado", "mecanico_id", "tomada_en", "terminada_en",
                         "created_at", "orden", "notas")
      )
      expect(tareas.map { |tarea| tarea["orden"].keys }).to all(contain_exactly("id", "vehiculo", "cliente"))
    end

    it "incluye las notas de cada tarea" do
      disponible = create(:tarea, orden: orden)
      create(:tarea_nota, tarea: disponible, contenido: "Pidió que la revisen urgente", registrado_por: mecanico)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      expect(response.parsed_body["disponibles"].first["notas"].pluck("contenido"))
        .to eq([ "Pidió que la revisen urgente" ])
    end

    it "incluye las tareas que el mecánico terminó hoy, ordenadas por más reciente" do
      mas_vieja = create(:tarea, :terminada, orden: orden, mecanico: mecanico, terminada_en: 3.hours.ago)
      mas_nueva = create(:tarea, :terminada, orden: orden, mecanico: mecanico, terminada_en: 1.hour.ago)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      expect(response.parsed_body["terminadas_hoy"].pluck("id")).to eq([ mas_nueva.id, mas_vieja.id ])
    end

    it "no incluye tareas terminadas en días anteriores" do
      create(:tarea, :terminada, orden: orden, mecanico: mecanico, terminada_en: 2.days.ago)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      expect(response.parsed_body["terminadas_hoy"]).to be_empty
    end

    it "no incluye tareas terminadas por otro mecánico" do
      create(:tarea, :terminada, orden: orden, mecanico: otro_mecanico)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      expect(response.parsed_body["terminadas_hoy"]).to be_empty
    end

    it "incluye tareas terminadas hoy aunque la orden ya esté cerrada o cancelada" do
      terminada = create(:tarea, :terminada, orden: orden, mecanico: mecanico)
      orden.update!(estado: :cancelada, cancelada_en: Time.current)

      get "/tareas_mecanico", headers: auth_headers(mecanico)

      expect(response.parsed_body["terminadas_hoy"].pluck("id")).to eq([ terminada.id ])
    end

    it "usa el día calendario de Argentina, no el de UTC, para decidir qué es \"hoy\"" do
      zona_argentina = ActiveSupport::TimeZone["Buenos Aires"]
      noche_en_argentina = zona_argentina.parse("2026-10-23 23:30:00")
      manana_siguiente_en_argentina = zona_argentina.parse("2026-10-24 10:00:00")

      travel_to noche_en_argentina do
        create(:tarea, :terminada, orden: orden, mecanico: mecanico)
      end

      travel_to manana_siguiente_en_argentina do
        get "/tareas_mecanico", headers: auth_headers(mecanico)
      end

      expect(response.parsed_body["terminadas_hoy"]).to be_empty
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
