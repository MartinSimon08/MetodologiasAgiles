require "rails_helper"

RSpec.describe "Sesiones", type: :request do
  let!(:usuario) { create(:usuario, email: "juan@taller.test", password: PasswordsDePrueba::VALIDA) }

  describe "POST /sesion" do
    it "devuelve un token con credenciales válidas" do
      post "/sesion", params: { email: "Juan@taller.test", password: PasswordsDePrueba::VALIDA }, as: :json

      expect(response).to have_http_status(:created)
      payload = JsonWebToken.decode(response.parsed_body["token"])
      expect(payload).to include("usuario_id" => usuario.id, "rol" => "mecanico")
    end

    it "rechaza una contraseña incorrecta con un mensaje genérico" do
      post "/sesion", params: { email: "juan@taller.test", password: PasswordsDePrueba::INCORRECTA }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Email o contraseña incorrectos")
    end

    it "responde lo mismo cuando el usuario no existe" do
      post "/sesion", params: { email: "nadie@taller.test", password: PasswordsDePrueba::VALIDA }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Email o contraseña incorrectos")
    end

    it "rechaza credenciales vacías" do
      post "/sesion", params: {}, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Email o contraseña incorrectos")
    end

    it "rechaza a un usuario desactivado con el mensaje genérico" do
      usuario.update!(activo: false)

      post "/sesion", params: { email: "juan@taller.test", password: PasswordsDePrueba::VALIDA }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Email o contraseña incorrectos")
    end

    it "devuelve un token con el rol de administrador" do
      admin = create(:usuario, :administrador)

      post "/sesion", params: { email: admin.email, password: PasswordsDePrueba::VALIDA }, as: :json

      expect(JsonWebToken.decode(response.parsed_body["token"])).to include("rol" => "administrador")
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

    it "renueva el token en cada request autenticado" do
      get "/sesion", headers: auth_headers(usuario)

      renovado = JsonWebToken.decode(response.headers["X-Token-Renovado"])
      expect(renovado).to include("usuario_id" => usuario.id, "rol" => "mecanico")
    end

    it "no renueva el token si la request no está autenticada" do
      get "/sesion"

      expect(response.headers["X-Token-Renovado"]).to be_nil
    end

    it "expira la sesión tras el tiempo máximo de inactividad" do
      headers = auth_headers(usuario)

      travel JsonWebToken::INACTIVIDAD_MAXIMA + 1.second do
        get "/sesion", headers: headers
      end

      expect(response).to have_http_status(:unauthorized)
    end

    it "mantiene la sesión mientras haya actividad" do
      headers = auth_headers(usuario)

      travel JsonWebToken::INACTIVIDAD_MAXIMA - 1.minute do
        get "/sesion", headers: headers
        headers = { "Authorization" => "Bearer #{response.headers["X-Token-Renovado"]}" }
      end

      travel JsonWebToken::INACTIVIDAD_MAXIMA + 10.minutes do
        get "/sesion", headers: headers
      end

      expect(response).to have_http_status(:ok)
    end

    it "invalida la sesión activa de un usuario desactivado" do
      headers = auth_headers(usuario)
      usuario.update!(activo: false)

      get "/sesion", headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["X-Token-Renovado"]).to be_nil
    end

    it "rechaza un token vencido" do
      token = JsonWebToken.encode({ usuario_id: usuario.id }, exp: 1.minute.ago)

      get "/sesion", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
