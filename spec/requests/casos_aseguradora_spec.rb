require "rails_helper"

RSpec.describe "Casos de una aseguradora", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:aseguradora) { create(:aseguradora, nombre: "Sancor") }

  def consultar(params = { aseguradora_id: aseguradora.id, desde: "2026-04-01", hasta: "2026-04-30" }, usuario: admin)
    get "/casos/aseguradora", params: params, headers: usuario ? auth_headers(usuario) : {}
  end

  it "muestra una orden abierta y una cerrada con la franquicia registrada" do
    abierta = travel_to(Time.zone.local(2026, 4, 10, 12)) do
      create(:caso, aseguradora: aseguradora, numero_siniestro: "SIN-10")
    end
    orden_abierta = create(:orden, cliente: abierta.asegurado, vehiculo: abierta.vehiculo)
    create(:tarea, orden: orden_abierta, precio: "1000")
    create(:adelanto, orden: orden_abierta, importe: "200", registrado_por: admin)
    create(:adelanto, orden: orden_abierta, importe: "50", registrado_por: admin)
    abierta.update!(orden: orden_abierta)
    cerrada = travel_to(Time.zone.local(2026, 4, 12, 12)) do
      create(:caso, aseguradora: aseguradora, numero_siniestro: "SIN-11")
    end
    orden_cerrada = create(:orden, cliente: cerrada.asegurado, vehiculo: cerrada.vehiculo)
    create(:tarea, :terminada, orden: orden_cerrada, precio: "800", mecanico: admin)
    create(:adelanto, orden: orden_cerrada, importe: "100", registrado_por: admin)
    OrdenCerrar.call(orden: orden_cerrada, cerrada_por: admin, franquicia: "300")
    cerrada.update!(orden: orden_cerrada)
    sin_orden = travel_to(Time.zone.local(2026, 4, 14, 12)) do
      create(:caso, aseguradora: aseguradora, numero_siniestro: "SIN-12")
    end

    consultar

    expect(response).to have_http_status(:ok)
    cuerpo = response.parsed_body
    expect(cuerpo["casos"].pluck("id")).to eq([ abierta.id, cerrada.id, sin_orden.id ])
    expect(cuerpo["casos"].first).to include(
      "numero_siniestro" => "SIN-10",
      "orden_id" => orden_abierta.id,
      "orden_estado" => "abierta",
      "total_autorizado" => "1000.0",
      "franquicia_cobrada" => "0.0",
      "saldo_pendiente" => "1000.0",
      "asegurado" => a_hash_including("id" => abierta.asegurado_id),
      "vehiculo" => a_hash_including("id" => abierta.vehiculo_id, "patente" => abierta.vehiculo.patente)
    )
    expect(cuerpo["casos"].second).to include(
      "numero_siniestro" => "SIN-11",
      "orden_id" => orden_cerrada.id,
      "orden_estado" => "cerrada",
      "total_autorizado" => "800.0",
      "franquicia_cobrada" => "300.0",
      "saldo_pendiente" => "500.0"
    )
    expect(cuerpo["casos"].third).to include(
      "orden_id" => nil, "orden_estado" => nil, "total_autorizado" => "0.0", "franquicia_cobrada" => "0.0", "saldo_pendiente" => "0.0"
    )
    expect(cuerpo["totales"]).to eq(
      "total_autorizado" => "1800.0", "franquicia_cobrada" => "300.0", "saldo_pendiente" => "1500.0"
    )
  end

  it "devuelve cero cuando el período no tiene casos de esa aseguradora" do
    consultar

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "aseguradora" => aseguradora.as_json(only: %i[id nombre telefono email activa created_at]),
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
