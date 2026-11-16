require "rails_helper"

RSpec.describe "Envío del presupuesto a la aseguradora", type: :request do
  let(:administrador) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:orden) { create(:orden) }
  let(:aseguradora) { create(:aseguradora, :con_contacto) }
  let!(:caso) { create(:caso, orden: orden, aseguradora: aseguradora) }

  it "registra el envío por email y devuelve el destinatario" do
    expect {
      post "/ordenes/#{orden.id}/enviar_presupuesto", params: { medio: "email" },
           headers: auth_headers(administrador), as: :json
    }.to change(EnvioPresupuesto, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("medio" => "email", "destinatario" => aseguradora.email)
    expect(response.parsed_body["enviado_por"]).to include("nombre" => administrador.nombre)
  end

  it "expone el caso, el contacto y el historial en el presupuesto" do
    post "/ordenes/#{orden.id}/enviar_presupuesto", params: { medio: "whatsapp" },
         headers: auth_headers(administrador), as: :json

    get "/ordenes/#{orden.id}/presupuesto", headers: auth_headers(administrador)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["caso"]).to include("numero_siniestro" => caso.numero_siniestro)
    expect(response.parsed_body["aseguradora"]).to include("email" => aseguradora.email)
    expect(response.parsed_body["envios"].first).to include(
      "medio" => "whatsapp", "destinatario" => aseguradora.telefono
    )
  end

  it "rechaza el envío si la orden no tiene caso" do
    otra = create(:orden)

    post "/ordenes/#{otra.id}/enviar_presupuesto", params: { medio: "email" },
         headers: auth_headers(administrador), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]["base"]).to include("La orden no está vinculada a un caso")
  end

  it "prohíbe el envío a un mecánico" do
    post "/ordenes/#{orden.id}/enviar_presupuesto", params: { medio: "email" },
         headers: auth_headers(mecanico), as: :json

    expect(response).to have_http_status(:forbidden)
  end
end
