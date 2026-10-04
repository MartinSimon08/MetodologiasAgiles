require "rails_helper"

RSpec.describe "Repuestos", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }
  let(:orden) { create(:orden) }
  let(:atributos) { { descripcion: "Filtro", cantidad: 2, costo_unitario: "123.45", margen: "20" } }

  describe "GET /repuestos_catalogo" do
    it "lista los precios del catálogo con paginación y búsqueda por nombre" do
      create(:repuesto_catalogo, nombre: "Filtro de aceite", precio: "123.45")
      create(:repuesto_catalogo, nombre: "Filtro de aire")
      create(:repuesto_catalogo, nombre: "Bujía")

      get "/repuestos_catalogo", params: { buscar: " FILTRO ", por_pagina: 1 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["repuestos"]).to contain_exactly(
        include("nombre" => "filtro de aceite", "precio" => "123.45")
      )
      expect(response.parsed_body["meta"]).to include("total" => 2, "total_paginas" => 2)

      get "/repuestos_catalogo", params: { buscar: "filtro", por_pagina: 1, pagina: 2 }, headers: auth_headers(admin)
      expect(response.parsed_body["repuestos"].pluck("nombre")).to eq([ "filtro de aire" ])
    end

    it "busca los comodines de SQL como texto literal" do
      create(:repuesto_catalogo, nombre: "Filtro")

      get "/repuestos_catalogo", params: { buscar: "%" }, headers: auth_headers(admin)

      expect(response.parsed_body["repuestos"]).to eq([])
    end

    it "devuelve una lista vacía cuando todavía no se cargaron repuestos" do
      get "/repuestos_catalogo", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["repuestos"]).to eq([])
    end
  end

  describe "POST /ordenes/:orden_id/repuestos" do
    it "registra una compra ocasional sin agregarla al catálogo" do
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("precio_cliente" => "296.28", "ganancia" => "49.38", "registrado_por_id" => admin.id)
      expect(response.parsed_body["created_at"]).to be_present
      expect(response.parsed_body["repuesto_catalogo_id"]).to be_nil
      expect(RepuestoCatalogo.count).to eq(0)
    end

    it "reutiliza un artículo con un costo real diferente sin modificar el catálogo" do
      catalogo = create(:repuesto_catalogo, nombre: "Filtro")

      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: {
        repuesto_catalogo_id: catalogo.id, cantidad: 1, costo_unitario: "150"
      } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("descripcion" => "filtro", "costo_unitario" => "150.0")
      get "/repuestos_catalogo", headers: auth_headers(admin)
      expect(response.parsed_body["repuestos"]).to contain_exactly(include("precio" => "100.5"))
    end

    it "ignora valores calculados y el autor enviados por el cliente" do
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos.merge(
        precio_cliente: "1", registrado_por_id: mecanico.id, ultimo_costo: "1"
      ) }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(Repuesto.last).to have_attributes(precio_cliente: BigDecimal("296.28"), registrado_por_id: admin.id)
      expect(RepuestoCatalogo.count).to eq(0)
    end

    it "devuelve errores de campo para un costo inválido" do
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos.merge(costo_unitario: "-1") },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("costo_unitario")
      expect(RepuestoCatalogo.count).to eq(0)
    end

    it "rechaza compras en órdenes cerradas" do
      orden.update!(estado: :cerrada)
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("orden")
    end

    it "devuelve 404 para un artículo inexistente" do
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos.merge(repuesto_catalogo_id: 0) },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "devuelve 404 para una orden inexistente" do
      post "/ordenes/0/repuestos", params: { repuesto: atributos }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /ordenes/:orden_id/repuestos" do
    it "lista exclusivamente las compras de la orden y pagina los resultados" do
      ConfiguracionTaller.actual.update!(margen_repuestos: "25.25")
      RepuestoAgregar.call(orden: orden, registrado_por: admin, **atributos, proveedor: "Casa Central")
      RepuestoAgregar.call(orden: create(:orden), registrado_por: admin, **atributos.merge(descripcion: "Otra compra"))

      get "/ordenes/#{orden.id}/repuestos", params: { por_pagina: 1 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["repuestos"]).to contain_exactly(include(
        "descripcion" => "Filtro", "costo_unitario" => "123.45", "precio_cliente" => "296.28",
        "ganancia" => "49.38", "proveedor" => "Casa Central",
        "registrado_por" => { "id" => admin.id, "nombre" => admin.nombre }
      ))
      expect(response.parsed_body["repuestos"].first["created_at"]).to be_present
      expect(response.parsed_body["meta"]).to include("total" => 1)
      expect(response.parsed_body["margen_por_defecto"]).to eq("25.25")
    end
  end

  [ :get, :post ].each do |metodo|
    it "exige autenticación para #{metodo} de compras" do
      public_send(metodo, "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos }, as: :json)
      expect(response).to have_http_status(:unauthorized)
    end

    it "prohíbe a mecánicos #{metodo} de compras" do
      public_send(metodo, "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos }, headers: auth_headers(mecanico), as: :json)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "exige autenticación para consultar costos del catálogo" do
    get "/repuestos_catalogo"
    expect(response).to have_http_status(:unauthorized)
  end

  it "prohíbe a mecánicos consultar costos del catálogo" do
    get "/repuestos_catalogo", headers: auth_headers(mecanico)
    expect(response).to have_http_status(:forbidden)
  end
end
