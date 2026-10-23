require "rails_helper"

RSpec.describe "Notas de tareas", type: :request do
  let!(:admin) { create(:usuario, :administrador) }
  let!(:mecanico) { create(:usuario) }
  let!(:orden) { create(:orden) }
  let!(:tarea) { create(:tarea, orden: orden) }

  describe "POST /tareas/:tarea_id/notas" do
    let(:params) { { tarea_nota: { contenido: "Falta la junta del cárter" } } }

    it "permite a un mecánico agregar una nota a una tarea pendiente" do
      expect {
        post "/tareas/#{tarea.id}/notas", params: params, headers: auth_headers(mecanico), as: :json
      }.to change(TareaNota, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["contenido"]).to eq("Falta la junta del cárter")
      expect(response.parsed_body["registrado_por"]).to include("id" => mecanico.id, "nombre" => mecanico.nombre)
    end

    it "permite a un mecánico que no tomó la tarea agregar una nota" do
      otro_mecanico = create(:usuario)
      tarea.update!(estado: :en_curso, mecanico: otro_mecanico, tomada_en: Time.current)

      post "/tareas/#{tarea.id}/notas", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:created)
    end

    it "permite agregar una nota a una tarea ya terminada" do
      tarea.update!(estado: :terminada, mecanico: mecanico, tomada_en: 1.hour.ago, terminada_en: Time.current)

      post "/tareas/#{tarea.id}/notas", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:created)
    end

    it "rechaza un contenido vacío" do
      post "/tareas/#{tarea.id}/notas", params: { tarea_nota: { contenido: "" } },
                                         headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("contenido")
    end

    it "rechaza agregar una nota si la orden está cerrada" do
      orden.update!(estado: :cerrada)

      post "/tareas/#{tarea.id}/notas", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("orden")
    end

    it "prohíbe a un administrador agregar una nota" do
      post "/tareas/#{tarea.id}/notas", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      post "/tareas/#{tarea.id}/notas", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "devuelve 404 si la tarea no existe" do
      post "/tareas/0/notas", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
