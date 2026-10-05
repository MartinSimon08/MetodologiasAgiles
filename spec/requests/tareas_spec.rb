require "rails_helper"

RSpec.describe "Tareas", type: :request do
  let!(:admin) { create(:usuario, :administrador) }
  let!(:mecanico) { create(:usuario) }
  let!(:orden) { create(:orden) }

  describe "POST /ordenes/:orden_id/tareas" do
    let(:params) { { tarea: { descripcion: "Cambiar aceite" } } }

    it "permite a un administrador crear una tarea pendiente" do
      expect {
        post "/ordenes/#{orden.id}/tareas", params: params, headers: auth_headers(admin), as: :json
      }.to change(Tarea, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("descripcion" => "Cambiar aceite", "estado" => "pendiente")
    end

    it "permite cargar un precio, por ejemplo el sugerido por el catálogo" do
      post "/ordenes/#{orden.id}/tareas", params: { tarea: params[:tarea].merge(precio: "15000") },
                                          headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["precio"]).to eq(15_000.0)
    end

    it "rechaza un precio negativo" do
      post "/ordenes/#{orden.id}/tareas", params: { tarea: params[:tarea].merge(precio: "-1") },
                                          headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("precio")
    end

    it "rechaza una descripción vacía" do
      post "/ordenes/#{orden.id}/tareas", params: { tarea: { descripcion: "" } },
                                          headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("descripcion")
    end

    it "rechaza crear tareas en una orden cerrada" do
      orden.update!(estado: :cerrada)

      post "/ordenes/#{orden.id}/tareas", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("orden")
    end

    it "rechaza crear tareas en una orden cancelada" do
      orden.update!(estado: :cancelada, cancelada_en: Time.current)

      post "/ordenes/#{orden.id}/tareas", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["orden"]).to include("Orden está cancelada")
    end

    it "prohíbe a un mecánico crear tareas" do
      post "/ordenes/#{orden.id}/tareas", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      post "/ordenes/#{orden.id}/tareas", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "devuelve 404 si la orden no existe" do
      post "/ordenes/0/tareas", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /ordenes/:orden_id/tareas" do
    it "lista las tareas de la orden" do
      create(:tarea, orden: orden, descripcion: "Cambiar aceite")
      create(:tarea, descripcion: "De otra orden")

      get "/ordenes/#{orden.id}/tareas", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tareas"].pluck("descripcion")).to eq([ "Cambiar aceite" ])
    end

    it "permite a un administrador consultarlas en modo solo lectura" do
      create(:tarea, orden: orden, descripcion: "Cambiar aceite")

      get "/ordenes/#{orden.id}/tareas", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tareas"].pluck("descripcion")).to eq([ "Cambiar aceite" ])
    end

    it "le muestra el precio de cada tarea al administrador" do
      create(:tarea, orden: orden, precio: 15_000)

      get "/ordenes/#{orden.id}/tareas", headers: auth_headers(admin)

      expect(response.parsed_body["tareas"].first["precio"]).to eq(15_000.0)
    end

    it "le devuelve las tareas sin importes al mecánico" do
      create(:tarea, :en_curso, orden: orden, mecanico: mecanico, precio: 15_000)

      get "/ordenes/#{orden.id}/tareas", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tareas"].first.keys).to contain_exactly(
        "id", "orden_id", "descripcion", "estado", "mecanico_id", "mecanico", "tomada_en", "terminada_en", "created_at"
      )
    end
  end

  describe "PATCH /tareas/:id/tomar" do
    let!(:tarea) { create(:tarea, orden: orden) }

    it "permite a un mecánico tomar una tarea pendiente" do
      patch "/tareas/#{tarea.id}/tomar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("estado" => "en_curso", "mecanico_id" => mecanico.id)
      expect(response.parsed_body["mecanico"]).to include("id" => mecanico.id, "nombre" => mecanico.nombre)
      expect(response.parsed_body["tomada_en"]).to be_present
    end

    it "rechaza tomar una tarea que ya está en curso" do
      otro_mecanico = create(:usuario)
      patch "/tareas/#{tarea.id}/tomar", headers: auth_headers(otro_mecanico)

      patch "/tareas/#{tarea.id}/tomar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rechaza tomar una tarea de una orden cancelada" do
      orden.update!(estado: :cancelada, cancelada_en: Time.current)

      patch "/tareas/#{tarea.id}/tomar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["orden"]).to include("Orden está cancelada")
      expect(tarea.reload).to be_pendiente
    end

    it "prohíbe a un administrador tomar tareas" do
      patch "/tareas/#{tarea.id}/tomar", headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
    end

    it "no le devuelve el precio de la tarea al mecánico" do
      tarea.update!(precio: 15_000)

      patch "/tareas/#{tarea.id}/tomar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).not_to have_key("precio")
    end
  end

  describe "PATCH /tareas/:id/completar" do
    let!(:tarea) { create(:tarea, :en_curso, orden: orden, mecanico: mecanico) }

    it "permite al mecánico responsable completarla" do
      patch "/tareas/#{tarea.id}/completar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["estado"]).to eq("terminada")
    end

    it "prohíbe a otro mecánico completarla" do
      otro_mecanico = create(:usuario)

      patch "/tareas/#{tarea.id}/completar", headers: auth_headers(otro_mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(tarea.reload).to be_en_curso
    end

    it "prohíbe completar una tarea que nadie tomó" do
      pendiente = create(:tarea, orden: orden)

      patch "/tareas/#{pendiente.id}/completar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(pendiente.reload).to be_pendiente
    end

    it "prohíbe a un administrador completarla" do
      patch "/tareas/#{tarea.id}/completar", headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
      expect(tarea.reload).to be_en_curso
    end

    it "no le devuelve el precio de la tarea al mecánico" do
      tarea.update!(precio: 15_000)

      patch "/tareas/#{tarea.id}/completar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).not_to have_key("precio")
    end
  end

  describe "PATCH /tareas/:id/liberar" do
    let!(:tarea) { create(:tarea, :en_curso, orden: orden, mecanico: mecanico) }

    it "permite al mecánico responsable liberarla" do
      patch "/tareas/#{tarea.id}/liberar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("estado" => "pendiente", "mecanico_id" => nil)
    end

    it "prohíbe a otro mecánico liberarla" do
      otro_mecanico = create(:usuario)

      patch "/tareas/#{tarea.id}/liberar", headers: auth_headers(otro_mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(tarea.reload).to be_en_curso
      expect(tarea.mecanico).to eq(mecanico)
    end

    it "prohíbe liberar una tarea que nadie tomó" do
      pendiente = create(:tarea, orden: orden)

      patch "/tareas/#{pendiente.id}/liberar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
    end

    it "prohíbe a un administrador liberarla" do
      patch "/tareas/#{tarea.id}/liberar", headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
      expect(tarea.reload.mecanico).to eq(mecanico)
    end

    it "no le devuelve el precio de la tarea al mecánico" do
      tarea.update!(precio: 15_000)

      patch "/tareas/#{tarea.id}/liberar", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).not_to have_key("precio")
    end
  end
end
