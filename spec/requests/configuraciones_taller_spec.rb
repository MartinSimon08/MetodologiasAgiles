require "rails_helper"

RSpec.describe "Configuración del taller", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  describe "GET /configuracion_taller" do
    it "devuelve el margen configurado" do
      ConfiguracionTaller.actual.update!(margen_repuestos: 27.5)

      get "/configuracion_taller", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("margen_repuestos" => 27.5, "cupo_diario" => 5)
    end

    it "prohíbe a un mecánico consultar el margen" do
      get "/configuracion_taller", headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end

    it "exige autenticación" do
      get "/configuracion_taller"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /configuracion_taller" do
    it "permite al administrador actualizar el margen" do
      patch "/configuracion_taller", params: { configuracion_taller: { margen_repuestos: 35.25 } },
                                      headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("margen_repuestos" => 35.25, "cupo_diario" => 5)
      expect(ConfiguracionTaller.actual.margen_repuestos).to eq(35.25)
    end

    it "rechaza un margen fuera del rango permitido" do
      ConfiguracionTaller.actual.update!(margen_repuestos: 20)

      patch "/configuracion_taller", params: { configuracion_taller: { margen_repuestos: 101 } },
                                      headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("margen_repuestos")
      expect(ConfiguracionTaller.actual.reload.margen_repuestos).to eq(20)
    end

    it "permite al administrador actualizar el cupo diario sin tocar el margen" do
      ConfiguracionTaller.actual.update!(margen_repuestos: 20)

      patch "/configuracion_taller", params: { configuracion_taller: { cupo_diario: 8 } },
                                      headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("margen_repuestos" => 20.0, "cupo_diario" => 8)
      expect(ConfiguracionTaller.actual.reload.cupo_diario).to eq(8)
    end

    [ 0, -3, 2.5, nil ].each do |valor|
      it "rechaza el cupo diario #{valor.inspect}" do
        patch "/configuracion_taller", params: { configuracion_taller: { cupo_diario: valor } },
                                        headers: auth_headers(admin), as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to have_key("cupo_diario")
        expect(ConfiguracionTaller.actual.reload.cupo_diario).to eq(5)
      end
    end

    it "prohíbe a un mecánico actualizar el cupo diario" do
      patch "/configuracion_taller", params: { configuracion_taller: { cupo_diario: 9 } },
                                      headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(ConfiguracionTaller.actual.reload.cupo_diario).to eq(5)
    end

    it "rechaza un margen vacío" do
      patch "/configuracion_taller", params: { configuracion_taller: {} },
                                      headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"]).to have_key("configuracion_taller")
    end

    it "prohíbe a un mecánico actualizar el margen" do
      patch "/configuracion_taller", params: { configuracion_taller: { margen_repuestos: 30 } },
                                      headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación" do
      patch "/configuracion_taller", params: { configuracion_taller: { margen_repuestos: 30 } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
