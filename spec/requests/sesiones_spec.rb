require "rails_helper"

RSpec.describe "Sesiones", type: :request do
  let!(:usuario) { create(:usuario, email: "juan@taller.test", password: PasswordsDePrueba::VALIDA) }

  it "devuelve un token con credenciales válidas" do
    post "/sesion", params: { email: "Juan@taller.test", password: PasswordsDePrueba::VALIDA }, as: :json

    expect(response).to have_http_status(:created)
    payload = JsonWebToken.decode(response.parsed_body["token"])
    expect(payload).to include("usuario_id" => usuario.id, "rol" => "mecanico")
  end

  it "rechaza una contraseña incorrecta" do
    post "/sesion", params: { email: "juan@taller.test", password: PasswordsDePrueba::INCORRECTA }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
