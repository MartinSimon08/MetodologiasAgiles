require "rails_helper"

RSpec.describe "Adelantos", type: :request do
  let(:administrador) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:orden) { create(:orden) }

  before { create(:tarea, orden: orden, precio: 10_000) }

  describe "POST /ordenes/:orden_id/adelantos" do
    it "registra un adelanto del asegurado con su medio de pago" do
      post "/ordenes/#{orden.id}/adelantos",
           params: { adelanto: { importe: "3000", medio: "transferencia" } },
           headers: auth_headers(administrador)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("importe" => "3000.0", "medio" => "transferencia")
      expect(orden.adelantos.last.registrado_por).to eq(administrador)
    end

    it "usa efectivo como medio por defecto" do
      post "/ordenes/#{orden.id}/adelantos",
           params: { adelanto: { importe: "3000" } },
           headers: auth_headers(administrador)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["medio"]).to eq("efectivo")
    end

    it "rechaza un medio de pago desconocido" do
      post "/ordenes/#{orden.id}/adelantos",
           params: { adelanto: { importe: "3000", medio: "cheque" } },
           headers: auth_headers(administrador)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["medio"]).to include("Medio de pago no es un medio de pago válido")
    end

    it "prohíbe registrar adelantos a un mecánico" do
      post "/ordenes/#{orden.id}/adelantos",
           params: { adelanto: { importe: "3000", medio: "efectivo" } },
           headers: auth_headers(mecanico)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /ordenes/:orden_id/adelantos" do
    it "lista los adelantos con su medio de pago" do
      create(:adelanto, orden: orden, importe: "3000", medio: "tarjeta")

      get "/ordenes/#{orden.id}/adelantos", headers: auth_headers(administrador)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["adelantos"]).to include(
        a_hash_including("importe" => "3000.0", "medio" => "tarjeta")
      )
    end
  end
end
