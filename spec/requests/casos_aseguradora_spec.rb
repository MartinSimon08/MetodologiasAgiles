require "rails_helper"

RSpec.describe "Casos de una aseguradora", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:aseguradora) { create(:aseguradora, nombre: "Sancor") }

  def consultar(params = { aseguradora_id: aseguradora.id, desde: "2026-04-01", hasta: "2026-04-30" }, usuario: admin)
    get "/casos/aseguradora", params: params, headers: usuario ? auth_headers(usuario) : {}
  end

  it "muestra los casos del período con sus importes y los totales" do
    caso = travel_to(Time.zone.local(2026, 4, 10, 12)) do
      create(:caso, aseguradora: aseguradora, numero_siniestro: "SIN-10")
    end
    orden = create(:orden, cliente: caso.asegurado, vehiculo: caso.vehiculo)
    create(:tarea, orden: orden, precio: "1000")
    create(:adelanto, orden: orden, importe: "200", registrado_por: admin)
    create(:adelanto, orden: orden, importe: "50", registrado_por: admin)
    caso.update!(orden: orden)
    sin_orden = travel_to(Time.zone.local(2026, 4, 12, 12)) do
      create(:caso, aseguradora: aseguradora, numero_siniestro: "SIN-11")
    end

    consultar

    expect(response).to have_http_status(:ok)
    cuerpo = response.parsed_body
    expect(cuerpo["casos"].pluck("id")).to eq([ caso.id, sin_orden.id ])
    expect(cuerpo["casos"].first).to include(
      "numero_siniestro" => "SIN-10",
      "orden_id" => orden.id,
      "total_autorizado" => "1000.0",
      "franquicia_cobrada" => "250.0",
      "saldo_pendiente" => "750.0",
      "asegurado" => a_hash_including("id" => caso.asegurado_id),
      "vehiculo" => a_hash_including("id" => caso.vehiculo_id, "patente" => caso.vehiculo.patente)
    )
    expect(cuerpo["casos"].second).to include(
      "orden_id" => nil, "total_autorizado" => "0.0", "franquicia_cobrada" => "0.0", "saldo_pendiente" => "0.0"
    )
    expect(cuerpo["totales"]).to eq(
      "total_autorizado" => "1000.0", "franquicia_cobrada" => "250.0", "saldo_pendiente" => "750.0"
    )
  end

  it "devuelve cero cuando el período no tiene casos de esa aseguradora" do
    consultar

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "casos" => [],
      "totales" => { "total_autorizado" => "0.0", "franquicia_cobrada" => "0.0", "saldo_pendiente" => "0.0" }
    )
  end

  it "devuelve errores de campo para un período inválido o una aseguradora en blanco" do
    consultar({ hasta: "2026-04-30" })

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq(
      "aseguradora" => [ "no puede estar en blanco" ], "desde" => [ "no puede estar en blanco" ]
    )
  end

  it "exige autenticación" do
    consultar({ aseguradora_id: aseguradora.id, desde: "2026-04-01", hasta: "2026-04-30" }, usuario: nil)

    expect(response).to have_http_status(:unauthorized)
  end

  it "prohíbe a los mecánicos consultar los casos de una aseguradora" do
    consultar({ aseguradora_id: aseguradora.id, desde: "2026-04-01", hasta: "2026-04-30" }, usuario: mecanico)

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to be_empty
  end
end
