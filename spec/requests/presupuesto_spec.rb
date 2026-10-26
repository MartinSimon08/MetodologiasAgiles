require "rails_helper"

RSpec.describe "Presupuesto de la aseguradora", type: :request do
  let(:administrador) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:orden) { create(:orden) }

  it "muestra el presupuesto y el total, y deja el ítem rechazado en el detalle" do
    create(:tarea, orden: orden, descripcion: "Alineación", precio: 8_000)
    filtro = RepuestoAgregar.call(orden: orden, registrado_por: administrador, descripcion: "Filtro", cantidad: 1,
                                  costo_unitario: "1000", margen: 50)

    get "/ordenes/#{orden.id}/presupuesto", headers: auth_headers(administrador)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("presupuesto" => "9500.0", "total_aseguradora" => "9500.0")
    expect(response.parsed_body["tareas"]).to include(
      a_hash_including("descripcion" => "Alineación", "aprobacion" => "pendiente", "precio" => "8000.0")
    )

    patch "/ordenes/#{orden.id}/repuestos/#{filtro.id}/rechazar", headers: auth_headers(administrador)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("aprobacion" => "rechazado", "descripcion" => "Filtro")

    get "/ordenes/#{orden.id}/presupuesto", headers: auth_headers(administrador)

    expect(response.parsed_body["repuestos"]).to include(
      a_hash_including("descripcion" => "Filtro", "aprobacion" => "rechazado", "precio_cliente" => "1500.0")
    )
    expect(response.parsed_body).to include("presupuesto" => "9500.0", "total_aseguradora" => "8000.0")
  end

  it "permite aprobar una tarea y la vuelve a sumar si antes estaba rechazada" do
    tarea = create(:tarea, orden: orden, precio: 5_000, aprobacion: :rechazada)

    patch "/tareas/#{tarea.id}/aprobar", headers: auth_headers(administrador)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("aprobacion" => "aprobada")
    expect(orden.reload.total).to eq(5_000)
  end

  it "no deja rechazar un repuesto cuando el saldo quedaría negativo" do
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: administrador, descripcion: "Filtro", cantidad: 1,
                                    costo_unitario: "1500", margen: 0)
    create(:adelanto, orden: orden, importe: "1500", registrado_por: administrador)

    patch "/ordenes/#{orden.id}/repuestos/#{repuesto.id}/rechazar", headers: auth_headers(administrador)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]["base"]).to include(
      "El nuevo total quedaría por debajo de los adelantos ya registrados"
    )
    expect(repuesto.reload.aprobacion).to eq("pendiente")
    expect(orden.reload.saldo).to eq(0)
  end

  it "prohíbe el presupuesto y la decisión a un mecánico" do
    tarea = create(:tarea, orden: orden)
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: administrador, descripcion: "Filtro", cantidad: 1,
                                    costo_unitario: "100", margen: 0)

    get "/ordenes/#{orden.id}/presupuesto", headers: auth_headers(mecanico)
    expect(response).to have_http_status(:forbidden)

    patch "/tareas/#{tarea.id}/rechazar", headers: auth_headers(mecanico)
    expect(response).to have_http_status(:forbidden)

    patch "/ordenes/#{orden.id}/repuestos/#{repuesto.id}/aprobar", headers: auth_headers(mecanico)
    expect(response).to have_http_status(:forbidden)
  end
end
