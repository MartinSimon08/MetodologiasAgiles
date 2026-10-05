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
      expect(response.parsed_body).to include("precio_cliente" => "296.28", "ganancia" => "49.38",
                                              "registrado_por_id" => admin.id, "estado" => "valorizado")
      expect(response.parsed_body["created_at"]).to be_present
      expect(response.parsed_body["repuesto_catalogo_id"]).to be_nil
      expect(RepuestoCatalogo.count).to eq(0)
    end

    it "permite a un mecánico avisar que usó un repuesto, sin costo ni precio" do
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: { descripcion: "Filtro", cantidad: 2 } },
        headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("descripcion" => "Filtro", "cantidad" => 2, "estado" => "pendiente_de_valorizar",
                                              "costo_unitario" => nil, "margen" => nil, "precio_cliente" => nil, "ganancia" => nil,
                                              "registrado_por_id" => mecanico.id)
    end

    it "ignora el costo y el margen enviados por un mecánico al avisar" do
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos }, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:created)
      expect(Repuesto.last).to have_attributes(costo_unitario: nil, margen: nil, estado: "pendiente_de_valorizar")
    end

    it "rechaza el aviso de un mecánico en una orden cerrada" do
      orden.update!(estado: :cerrada)
      post "/ordenes/#{orden.id}/repuestos", params: { repuesto: { descripcion: "Filtro", cantidad: 2 } },
        headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("orden")
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
      RepuestoAgregar.call(orden: orden, registrado_por: admin, **atributos)
      RepuestoAgregar.call(orden: create(:orden), registrado_por: admin, **atributos.merge(descripcion: "Otra compra"))

      get "/ordenes/#{orden.id}/repuestos", params: { por_pagina: 1 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["repuestos"]).to contain_exactly(include("descripcion" => "Filtro", "costo_unitario" => "123.45"))
      expect(response.parsed_body["meta"]).to include("total" => 1)
    end
  end

  describe "PATCH /ordenes/:orden_id/repuestos/:id/valorizar" do
    let(:pendiente) { RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Filtro", cantidad: 2) }

    it "permite a administración cargar el costo de un aviso pendiente" do
      patch "/ordenes/#{orden.id}/repuestos/#{pendiente.id}/valorizar",
        params: { repuesto: { costo_unitario: "123.45", margen: "20" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("estado" => "valorizado", "costo_unitario" => "123.45", "margen" => "20.0",
                                              "precio_cliente" => "296.28", "ganancia" => "49.38")
    end

    it "usa el margen del taller si no se envía uno" do
      ConfiguracionTaller.actual.update!(margen_repuestos: "30.25")

      patch "/ordenes/#{orden.id}/repuestos/#{pendiente.id}/valorizar",
        params: { repuesto: { costo_unitario: "100" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("margen" => "30.25")
    end

    it "prohíbe a mecánicos valorizar" do
      patch "/ordenes/#{orden.id}/repuestos/#{pendiente.id}/valorizar",
        params: { repuesto: { costo_unitario: "100" } }, headers: auth_headers(mecanico), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "exige autenticación para valorizar" do
      patch "/ordenes/#{orden.id}/repuestos/#{pendiente.id}/valorizar", params: { repuesto: { costo_unitario: "100" } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "rechaza volver a valorizar un repuesto ya valorizado" do
      patch "/ordenes/#{orden.id}/repuestos/#{pendiente.id}/valorizar",
        params: { repuesto: { costo_unitario: "100" } }, headers: auth_headers(admin), as: :json

      patch "/ordenes/#{orden.id}/repuestos/#{pendiente.id}/valorizar",
        params: { repuesto: { costo_unitario: "120" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("estado")
    end

    it "devuelve errores de campo para un costo inválido" do
      patch "/ordenes/#{orden.id}/repuestos/#{pendiente.id}/valorizar",
        params: { repuesto: { costo_unitario: "-1" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("costo_unitario")
    end

    it "devuelve 404 si el repuesto no pertenece a la orden" do
      otra_orden = create(:orden)

      patch "/ordenes/#{otra_orden.id}/repuestos/#{pendiente.id}/valorizar",
        params: { repuesto: { costo_unitario: "100" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  it "exige autenticación para listar o registrar compras" do
    get "/ordenes/#{orden.id}/repuestos"
    expect(response).to have_http_status(:unauthorized)

    post "/ordenes/#{orden.id}/repuestos", params: { repuesto: atributos }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "prohíbe a mecánicos consultar las compras de la orden" do
    get "/ordenes/#{orden.id}/repuestos", headers: auth_headers(mecanico)
    expect(response).to have_http_status(:forbidden)
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
