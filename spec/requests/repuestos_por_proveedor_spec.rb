require "rails_helper"

RSpec.describe "Repuestos por proveedor", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  def agregar(**atributos)
    RepuestoAgregar.call(orden: create(:orden), registrado_por: admin, descripcion: "Filtro",
                         cantidad: 2, costo_unitario: "123.45", **atributos)
  end

  describe "GET /repuestos_por_proveedor" do
    it "lista el resumen por proveedor y pagina el detalle de las compras" do
      agregar(proveedor: "Casa Central")
      agregar(proveedor: "Casa Central", descripcion: "Bujía", cantidad: 1, costo_unitario: "50")
      agregar(proveedor: "Repuestos Centro")

      get "/repuestos_por_proveedor", params: { por_pagina: 1 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["proveedores"]).to eq([
        { "proveedor" => "Casa Central", "total_comprado" => "296.9", "cantidad_compras" => 2 },
        { "proveedor" => "Repuestos Centro", "total_comprado" => "246.9", "cantidad_compras" => 1 }
      ])
      expect(response.parsed_body["total_comprado"]).to eq("543.8")
      expect(response.parsed_body["repuestos"].size).to eq(1)
      expect(response.parsed_body["repuestos"].first).to include(
        "descripcion" => "Filtro", "cantidad" => 2, "costo_unitario" => "123.45",
        "total_costo" => "246.9", "proveedor" => "Repuestos Centro"
      )
      expect(response.parsed_body["repuestos"].first["orden"]).to include("id", "cliente", "vehiculo")
      expect(response.parsed_body["meta"]).to include("total" => 3, "total_paginas" => 3, "pagina" => 1)
    end

    it "filtra por proveedor y período" do
      travel_to(Time.utc(2026, 4, 10, 12)) { agregar(proveedor: "Casa Central") }
      travel_to(Time.utc(2026, 5, 10, 12)) { agregar(proveedor: "Casa Central", descripcion: "Fuera de período") }
      travel_to(Time.utc(2026, 4, 15, 12)) { agregar(proveedor: "Repuestos del Sur") }

      get "/repuestos_por_proveedor", params: { proveedor: "casa", desde: "2026-04-01", hasta: "2026-04-30" },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["proveedores"]).to contain_exactly(
        include("proveedor" => "Casa Central", "cantidad_compras" => 1)
      )
      expect(response.parsed_body["repuestos"].pluck("descripcion")).to eq([ "Filtro" ])
    end

    it "devuelve errores de campo para un período inválido" do
      get "/repuestos_por_proveedor", params: { desde: "ayer", hasta: "2026-01-01" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to eq("desde" => [ "no es una fecha válida" ])
    end

    it "exige autenticación" do
      get "/repuestos_por_proveedor"
      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a los mecánicos consultar las compras por proveedor" do
      get "/repuestos_por_proveedor", headers: auth_headers(mecanico)
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end
end
