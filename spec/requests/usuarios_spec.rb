require "rails_helper"

RSpec.describe "Usuarios", type: :request do
  let!(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  describe "POST /usuarios" do
    let(:params) do
      { usuario: { nombre: "Juan Pérez", email: "juan@taller.test", rol: "mecanico", password: "inicial123" } }
    end

    it "permite al administrador crear un mecánico" do
      expect {
        post "/usuarios", params: params, headers: auth_headers(admin), as: :json
      }.to change(Usuario, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("nombre" => "Juan Pérez", "email" => "juan@taller.test", "rol" => "mecanico")
      expect(response.parsed_body).not_to have_key("password_digest")
      expect(Usuario.find_by(email: "juan@taller.test").authenticate("inicial123")).to be_truthy
    end

    it "permite al administrador crear otro administrador" do
      post "/usuarios", params: { usuario: params[:usuario].merge(rol: "administrador") },
                        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(Usuario.find_by(email: "juan@taller.test")).to be_administrador
    end

    it "rechaza un email ya usado por otra cuenta" do
      create(:usuario, email: "juan@taller.test")

      post "/usuarios", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("email")
    end

    it "rechaza datos incompletos" do
      post "/usuarios", params: { usuario: { email: "juan@taller.test" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"].keys).to include("nombre", "rol", "password")
    end

    it "rechaza un rol inválido" do
      post "/usuarios", params: { usuario: params[:usuario].merge(rol: "gerente") },
                        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("rol")
    end

    it "prohíbe a un mecánico crear usuarios" do
      post "/usuarios", params: params, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      post "/usuarios", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /usuarios" do
    it "lista los usuarios para el administrador" do
      mecanico

      get "/usuarios", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("email")).to contain_exactly(admin.email, mecanico.email)
    end

    it "prohíbe el listado a un mecánico" do
      get "/usuarios", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /usuarios/:id/resetear_password" do
    it "permite al administrador resetear la contraseña de otro usuario" do
      patch "/usuarios/#{mecanico.id}/resetear_password", params: { password: "nueva12345" },
                                                           headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:no_content)
      expect(mecanico.reload.authenticate("nueva12345")).to be_truthy
    end

    it "rechaza una contraseña demasiado corta" do
      patch "/usuarios/#{mecanico.id}/resetear_password", params: { password: "corta" },
                                                           headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "prohíbe a un mecánico resetear contraseñas" do
      otro = create(:usuario)

      patch "/usuarios/#{otro.id}/resetear_password", params: { password: "nueva12345" },
                                                       headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "devuelve 404 si el usuario no existe" do
      patch "/usuarios/0/resetear_password", params: { password: "nueva12345" },
                                             headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
