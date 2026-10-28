require "rails_helper"

RSpec.describe "Administración de aseguradoras", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:aseguradora) { create(:aseguradora, :con_contacto) }

  describe "GET /aseguradoras" do
    it "lista activas y desactivadas ordenadas por nombre" do
      create(:aseguradora, nombre: "Sancor")
      create(:aseguradora, :desactivada, nombre: "Allianz")

      get "/aseguradoras", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["aseguradoras"].map { |a| [ a["nombre"], a["activa"] ] }).to eq([ [ "Allianz", false ], [ "Sancor", true ] ])
      expect(response.parsed_body["meta"]).to include("total" => 2)
    end

    it "filtra solo las activas" do
      create(:aseguradora, nombre: "Sancor")
      create(:aseguradora, :desactivada, nombre: "Allianz")

      get "/aseguradoras", params: { solo_activas: "true" }, headers: auth_headers(admin)

      expect(response.parsed_body["aseguradoras"].pluck("nombre")).to eq([ "Sancor" ])
    end

    it "busca por nombre sin distinguir mayúsculas" do
      create(:aseguradora, nombre: "La Segunda")
      create(:aseguradora, nombre: "Sancor")

      get "/aseguradoras", params: { buscar: "SEGUN" }, headers: auth_headers(admin)

      expect(response.parsed_body["aseguradoras"].pluck("nombre")).to eq([ "La Segunda" ])
    end
  end

  describe "POST /aseguradoras" do
    it "crea una aseguradora activa con nombre y contacto" do
      post "/aseguradoras", params: { aseguradora: { nombre: "  La   Segunda ", telefono: "(011) 4555-1234", email: "Siniestros@LaSegunda.TEST" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("id" => Aseguradora.last.id, "nombre" => "La Segunda", "telefono" => "01145551234",
                                              "email" => "siniestros@lasegunda.test", "activa" => true)
    end

    it "crea una aseguradora sin contacto" do
      post "/aseguradoras", params: { aseguradora: { nombre: "Sancor" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("telefono" => nil, "email" => nil)
    end

    it "rechaza un nombre repetido sin distinguir mayúsculas ni espacios" do
      create(:aseguradora, nombre: "La Segunda")

      expect {
        post "/aseguradoras", params: { aseguradora: { nombre: " LA   segunda " } }, headers: auth_headers(admin), as: :json
      }.not_to change(Aseguradora, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("nombre")
    end

    it "rechaza un nombre repetido de una aseguradora desactivada" do
      create(:aseguradora, :desactivada, nombre: "Allianz")

      post "/aseguradoras", params: { aseguradora: { nombre: "Allianz" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("nombre")
    end

    [ { nombre: " " }, { nombre: "a" * 201 }, { telefono: "11-ABCD" }, { email: "siniestros" } ].each do |invalido|
      it "rechaza datos inválidos #{invalido.inspect}" do
        post "/aseguradoras", params: { aseguradora: { nombre: "Sancor" }.merge(invalido) }, headers: auth_headers(admin), as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to have_key(invalido.keys.first.to_s)
        expect(Aseguradora.count).to eq(0)
      end
    end

    it "ignora el estado enviado al crear" do
      post "/aseguradoras", params: { aseguradora: { nombre: "Sancor", activa: false } }, headers: auth_headers(admin), as: :json

      expect(Aseguradora.last).to be_activa
    end
  end

  describe "PATCH /aseguradoras/:id" do
    it "edita nombre y contacto" do
      patch "/aseguradoras/#{aseguradora.id}", params: { aseguradora: { nombre: "Rivadavia", telefono: "", email: "nuevo@rivadavia.test" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(aseguradora.reload).to have_attributes(nombre: "Rivadavia", telefono: nil, email: "nuevo@rivadavia.test")
    end

    it "permite cambiar solo las mayúsculas del propio nombre" do
      aseguradora.update!(nombre: "sancor")

      patch "/aseguradoras/#{aseguradora.id}", params: { aseguradora: { nombre: "Sancor" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(aseguradora.reload.nombre).to eq("Sancor")
    end

    it "rechaza renombrar con el nombre de otra aseguradora" do
      create(:aseguradora, nombre: "Allianz")

      patch "/aseguradoras/#{aseguradora.id}", params: { aseguradora: { nombre: "ALLIANZ" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("nombre")
    end

    it "edita una aseguradora desactivada sin reactivarla" do
      desactivada = create(:aseguradora, :desactivada)

      patch "/aseguradoras/#{desactivada.id}", params: { aseguradora: { email: "a@b.test", activa: true } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(desactivada.reload).to have_attributes(email: "a@b.test", activa: false)
    end

    it "devuelve 404 para una aseguradora inexistente" do
      patch "/aseguradoras/0", params: { aseguradora: { nombre: "X" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /aseguradoras/:id/desactivar" do
    it "desactiva la aseguradora y la conserva" do
      patch "/aseguradoras/#{aseguradora.id}/desactivar", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id" => aseguradora.id, "activa" => false)
      expect(aseguradora.reload).not_to be_activa
    end

    it "rechaza desactivar una aseguradora ya desactivada" do
      aseguradora.update!(activa: false)

      patch "/aseguradoras/#{aseguradora.id}/desactivar", headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["base"]).to eq([ "La aseguradora ya está desactivada" ])
    end
  end

  describe "PATCH /aseguradoras/:id/activar" do
    it "reactiva una aseguradora desactivada" do
      aseguradora.update!(activa: false)

      patch "/aseguradoras/#{aseguradora.id}/activar", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(aseguradora.reload).to be_activa
    end

    it "rechaza activar una aseguradora ya activa" do
      patch "/aseguradoras/#{aseguradora.id}/activar", headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["base"]).to eq([ "La aseguradora ya está activa" ])
    end
  end

  describe "DELETE /aseguradoras/:id" do
    it "elimina una aseguradora sin casos" do
      delete "/aseguradoras/#{aseguradora.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:no_content)
      expect(Aseguradora.exists?(aseguradora.id)).to be(false)
    end

    it "permite volver a cargar el nombre eliminado" do
      delete "/aseguradoras/#{aseguradora.id}", headers: auth_headers(admin)
      post "/aseguradoras", params: { aseguradora: { nombre: aseguradora.nombre } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
    end

    it "no elimina una aseguradora con casos" do
      create(:caso, aseguradora: aseguradora)

      delete "/aseguradoras/#{aseguradora.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["base"]).to eq([ "No se puede eliminar porque existen casos dependientes" ])
      expect(Aseguradora.exists?(aseguradora.id)).to be(true)
    end

    it "devuelve 404 para una aseguradora inexistente" do
      delete "/aseguradoras/0", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  [ :post, :patch, :delete ].each do |metodo|
    it "prohíbe a mecánicos #{metodo} de aseguradoras" do
      ruta = metodo == :post ? "/aseguradoras" : "/aseguradoras/#{aseguradora.id}"
      public_send(metodo, ruta, params: { aseguradora: { nombre: "Cambio" } }, headers: auth_headers(create(:usuario)), as: :json)

      expect(response).to have_http_status(:forbidden)
      expect(aseguradora.reload.nombre).not_to eq("Cambio")
    end
  end
end
