require "rails_helper"

RSpec.describe "Usuarios", type: :request do
  let!(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  describe "POST /usuarios" do
    let(:params) do
      { usuario: { nombre: "Juan Pérez", email: "juan@taller.test", rol: "mecanico", password: PasswordsDePrueba::INICIAL } }
    end

    it "permite al administrador crear un mecánico" do
      expect {
        post "/usuarios", params: params, headers: auth_headers(admin), as: :json
      }.to change(Usuario, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("nombre" => "Juan Pérez", "email" => "juan@taller.test", "rol" => "mecanico")
      expect(response.parsed_body).not_to have_key("password_digest")
      expect(Usuario.find_by(email: "juan@taller.test").authenticate(PasswordsDePrueba::INICIAL)).to be_truthy
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
      expect(response.parsed_body["usuarios"].pluck("email")).to contain_exactly(admin.email, mecanico.email)
      expect(response.parsed_body["meta"]).to eq(
        "pagina" => 1, "por_pagina" => 20, "total" => 2, "total_paginas" => 1
      )
    end

    it "pagina los resultados ordenados por nombre" do
      %w[Carla Ana Bruno Diego].each { |nombre| create(:usuario, nombre: nombre) }
      admin.update!(nombre: "Zoe")

      get "/usuarios", params: { pagina: 2, por_pagina: 2 }, headers: auth_headers(admin)

      expect(response.parsed_body["usuarios"].pluck("nombre")).to eq(%w[Carla Diego])
      expect(response.parsed_body["meta"]).to eq(
        "pagina" => 2, "por_pagina" => 2, "total" => 5, "total_paginas" => 3
      )
    end

    it "limita la cantidad por página" do
      get "/usuarios", params: { por_pagina: 1000 }, headers: auth_headers(admin)

      expect(response.parsed_body["meta"]["por_pagina"]).to eq(100)
    end

    it "devuelve la última página si se pide una fuera de rango" do
      get "/usuarios", params: { pagina: 99 }, headers: auth_headers(admin)

      expect(response.parsed_body["meta"]["pagina"]).to eq(1)
      expect(response.parsed_body["usuarios"].pluck("email")).to eq([ admin.email ])
    end

    it "prohíbe el listado a un mecánico" do
      get "/usuarios", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /usuarios/:id/resetear_password" do
    it "permite al administrador resetear la contraseña de otro usuario" do
      patch "/usuarios/#{mecanico.id}/resetear_password", params: { password: PasswordsDePrueba::NUEVA },
                                                           headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:no_content)
      expect(mecanico.reload.authenticate(PasswordsDePrueba::NUEVA)).to be_truthy
    end

    it "rechaza una contraseña demasiado corta" do
      patch "/usuarios/#{mecanico.id}/resetear_password", params: { password: PasswordsDePrueba::CORTA },
                                                           headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "prohíbe a un mecánico resetear contraseñas" do
      otro = create(:usuario)

      patch "/usuarios/#{otro.id}/resetear_password", params: { password: PasswordsDePrueba::NUEVA },
                                                       headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "devuelve 404 si el usuario no existe" do
      patch "/usuarios/0/resetear_password", params: { password: PasswordsDePrueba::NUEVA },
                                             headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /usuarios/:id/desactivar" do
    it "desactiva al mecánico, libera sus tareas en curso e invalida su sesión" do
      headers_mecanico = auth_headers(mecanico)
      tarea = create(:tarea, :en_curso, mecanico: mecanico)

      patch "/usuarios/#{mecanico.id}/desactivar", headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id" => mecanico.id, "activo" => false)
      expect(response.parsed_body["tareas_liberadas"]).to eq(
        [ { "id" => tarea.id, "orden_id" => tarea.orden_id, "descripcion" => tarea.descripcion } ]
      )
      expect(tarea.reload).to be_pendiente

      get "/sesion", headers: headers_mecanico
      expect(response).to have_http_status(:unauthorized)
    end

    it "mantiene el nombre del mecánico en sus tareas terminadas" do
      tarea = create(:tarea, :terminada, mecanico: mecanico)

      patch "/usuarios/#{mecanico.id}/desactivar", headers: auth_headers(admin), as: :json
      get "/ordenes/#{tarea.orden_id}/tareas", headers: auth_headers(admin)

      expect(response.parsed_body["tareas"].first["mecanico"]).to eq("id" => mecanico.id, "nombre" => mecanico.nombre)
    end

    it "impide desactivar al último administrador activo" do
      patch "/usuarios/#{admin.id}/desactivar", headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["base"]).to eq([ "No se puede desactivar al último administrador activo" ])
      expect(admin.reload).to be_activo
    end

    it "prohíbe a un mecánico desactivar usuarios" do
      otro = create(:usuario)

      patch "/usuarios/#{otro.id}/desactivar", headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(otro.reload).to be_activo
    end

    it "devuelve 404 si el usuario no existe" do
      patch "/usuarios/0/desactivar", headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /usuarios con tareas en curso" do
    it "informa el estado y la cantidad de tareas en curso de cada usuario" do
      create_list(:tarea, 2, :en_curso, mecanico: mecanico)
      create(:tarea, :terminada, mecanico: mecanico)

      get "/usuarios", headers: auth_headers(admin)

      datos = response.parsed_body["usuarios"].index_by { |usuario| usuario["id"] }
      expect(datos[mecanico.id]).to include("activo" => true, "tareas_en_curso" => 2)
      expect(datos[admin.id]).to include("tareas_en_curso" => 0)
    end
  end
end
