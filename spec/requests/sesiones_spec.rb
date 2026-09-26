require "rails_helper"

RSpec.describe "Sesiones", type: :request do
  let!(:usuario) { create(:usuario, email: "juan@taller.test", password: "secreto123") }

  describe "POST /sesion" do
    it "devuelve un token con credenciales válidas" do
      post "/sesion", params: { email: "Juan@taller.test", password: "secreto123" }, as: :json

      expect(response).to have_http_status(:created)
      payload = JsonWebToken.decode(response.parsed_body["token"])
      expect(payload).to include("usuario_id" => usuario.id, "rol" => "mecanico")
    end

    it "rechaza una contraseña incorrecta" do
      post "/sesion", params: { email: "juan@taller.test", password: "otra" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /sesion" do
    it "devuelve el usuario autenticado" do
      get "/sesion", headers: auth_headers(usuario)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "id" => usuario.id, "nombre" => usuario.nombre, "email" => "juan@taller.test", "rol" => "mecanico"
      )
    end

    it "exige autenticación" do
      get "/sesion"

      expect(response).to have_http_status(:unauthorized)
    end

    it "rechaza un token vencido" do
      token = JsonWebToken.encode({ usuario_id: usuario.id }, exp: 1.minute.ago)

      get "/sesion", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
