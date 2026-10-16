require "rails_helper"

RSpec.describe "Ajustes de repuestos", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:orden) { create(:orden) }
  let(:repuesto) do
    RepuestoAgregar.call(
      orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 2,
      costo_unitario: "123.45", margen: "20", proveedor: "Casa Central"
    )
  end
  let(:ajuste) { { tipo: "devolucion", cantidad: 1, costo_unitario: "123.45", motivo: "Falla de fábrica" } }

  def post_ajuste(orden_id: orden.id, repuesto_id: repuesto.id, cuerpo: ajuste, usuario: admin)
    post "/ordenes/#{orden_id}/repuestos/#{repuesto_id}/ajustes",
      params: { ajuste: cuerpo }, headers: usuario ? auth_headers(usuario) : {}, as: :json
  end

  it "registra la devolución y la muestra en el historial sin cambiar el precio original" do
    post_ajuste

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include(
      "tipo" => "devolucion", "cantidad" => 1, "costo_unitario" => "123.45",
      "ajuste_costo" => "-123.45", "ajuste_precio_cliente" => "-148.14", "precio_original" => "148.14",
      "motivo" => "Falla de fábrica", "registrado_por" => { "id" => admin.id, "nombre" => admin.nombre }
    )
    expect(response.parsed_body["registrado_en"]).to be_present

    get "/ordenes/#{orden.id}/repuestos", headers: auth_headers(admin)

    compra = response.parsed_body["repuestos"].sole
    expect(compra).to include(
      "precio_cliente" => "296.28", "precio_vigente" => "148.14", "costo_vigente" => "123.45",
      "cantidad_disponible" => 1, "ganancia" => "49.38"
    )
    expect(compra["ajustes"].sole).to include("tipo" => "devolucion", "motivo" => "Falla de fábrica")
    expect(response.parsed_body["meta"]).to include("total" => 1)
  end

  it "registra un cambio e ignora importes calculados enviados por el cliente" do
    post_ajuste(cuerpo: ajuste.merge(tipo: "cambio", costo_unitario: "100", precio_original: "1", ajuste_precio_cliente: "1"))

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("tipo" => "cambio", "precio_original" => "148.14", "ajuste_precio_cliente" => "-28.14")
    expect(Repuesto.find(repuesto.id).precio_cliente).to eq(BigDecimal("296.28"))
  end

  it "prohíbe a mecánicos registrar un ajuste" do
    post_ajuste(usuario: mecanico)

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to be_empty
    expect(AjusteRepuesto.count).to eq(0)
  end

  it "exige autenticación" do
    post_ajuste(usuario: nil)

    expect(response).to have_http_status(:unauthorized)
  end

  it "rechaza una orden cerrada y no modifica el total" do
    repuesto
    total = orden.total
    orden.update!(estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin, total_cerrado: total)

    post_ajuste

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]["orden"]).to include(
      "Orden está cerrada y su total está congelado. Hay que reabrir la orden para corregirlo"
    )
    expect(AjusteRepuesto.count).to eq(0)
    expect(orden.reload.total).to eq(BigDecimal("296.28"))
  end

  it "rechaza un repuesto de otra orden" do
    post_ajuste(orden_id: create(:orden).id)

    expect(response).to have_http_status(:not_found)
  end

  it "devuelve errores de campo y no guarda el ajuste" do
    expect { post_ajuste(cuerpo: ajuste.merge(costo_unitario: "-1", motivo: "")) }
      .not_to change(AjusteRepuesto, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to include("costo_unitario", "motivo")
  end

  it "exige el cuerpo del ajuste" do
    post "/ordenes/#{orden.id}/repuestos/#{repuesto.id}/ajustes", params: {}, headers: auth_headers(admin), as: :json

    expect(response).to have_http_status(:bad_request)
  end
end
