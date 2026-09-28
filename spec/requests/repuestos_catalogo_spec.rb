require "rails_helper"

RSpec.describe "Administración del catálogo de repuestos", type: :request do
  let(:admin) { create(:usuario, :administrador) }
  let(:catalogo) { create(:repuesto_catalogo) }

  describe "POST /repuestos_catalogo" do
    it "carga nombre y precio sin necesitar una orden ni cantidades" do
      post "/repuestos_catalogo", params: { repuesto_catalogo: { nombre: "  FILTRO   de aceite ", precio: "123.45", cantidad: 10 } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq("id" => RepuestoCatalogo.last.id, "nombre" => "filtro de aceite", "precio" => "123.45")
      expect(Repuesto.count).to eq(0)
      expect(Orden.count).to eq(0)
    end

    it "rechaza nombres duplicados normalizando mayúsculas y espacios" do
      create(:repuesto_catalogo, nombre: "Filtro de aceite")

      expect {
        post "/repuestos_catalogo", params: { repuesto_catalogo: { nombre: " FILTRO   de aceite ", precio: "120" } },
          headers: auth_headers(admin), as: :json
      }.not_to change(RepuestoCatalogo, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("nombre")
    end

    [ { nombre: " " }, { nombre: "a" * 201 }, { precio: nil }, { precio: "-1" },
      { precio: "abc" }, { precio: "10000000000" } ].each do |invalido|
      it "rechaza datos inválidos #{invalido.inspect}" do
        post "/repuestos_catalogo", params: { repuesto_catalogo: { nombre: "Filtro", precio: "100" }.merge(invalido) },
          headers: auth_headers(admin), as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to have_key(invalido.keys.first.to_s)
        expect(RepuestoCatalogo.count).to eq(0)
      end
    end

    it "acepta un precio cero" do
      post "/repuestos_catalogo", params: { repuesto_catalogo: { nombre: "Filtro", precio: "0" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(RepuestoCatalogo.last.precio).to eq(0)
    end
  end

  describe "PATCH /repuestos_catalogo/:id" do
    it "edita nombre y precio" do
      patch "/repuestos_catalogo/#{catalogo.id}", params: { repuesto_catalogo: { nombre: " Bujía ", precio: "150.25" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(catalogo.reload).to have_attributes(nombre: "bujía", precio: BigDecimal("150.25"))
    end

    it "permite actualizar solamente el precio" do
      nombre = catalogo.nombre
      patch "/repuestos_catalogo/#{catalogo.id}", params: { repuesto_catalogo: { precio: "0" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(catalogo.reload).to have_attributes(nombre: nombre, precio: BigDecimal("0"))
    end

    it "conserva el artículo ante un precio inválido" do
      patch "/repuestos_catalogo/#{catalogo.id}", params: { repuesto_catalogo: { nombre: "Cambio", precio: "-1" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(catalogo.reload.precio).to eq(BigDecimal("100.50"))
      expect(catalogo.nombre).not_to eq("cambio")
    end

    it "rechaza renombrar un artículo con el nombre de otro" do
      create(:repuesto_catalogo, nombre: "Filtro de aire")
      patch "/repuestos_catalogo/#{catalogo.id}", params: { repuesto_catalogo: { nombre: " FILTRO de aire " } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("nombre")
    end

    it "devuelve 404 para un artículo inexistente" do
      patch "/repuestos_catalogo/0", params: { repuesto_catalogo: { precio: "100" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /repuestos_catalogo/:id" do
    it "elimina el artículo del listado y las sugerencias" do
      delete "/repuestos_catalogo/#{catalogo.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:no_content)
      expect(RepuestoCatalogo.exists?(catalogo.id)).to be(false)

      get "/repuestos_catalogo", params: { buscar: catalogo.nombre }, headers: auth_headers(admin)
      expect(response.parsed_body["repuestos"]).to eq([])
    end

    it "conserva todos los datos de los repuestos cargados en órdenes abiertas o cerradas" do
      orden_abierta = create(:orden)
      orden_cerrada = create(:orden)
      repuestos = [ orden_abierta, orden_cerrada ].map do |orden|
        RepuestoAgregar.call(orden: orden, registrado_por: admin, repuesto_catalogo_id: catalogo.id,
                             cantidad: 2, costo_unitario: "100", margen: "25", proveedor: "Proveedor Demo")
      end
      orden_cerrada.update!(estado: :cerrada)
      datos = repuestos.map { |repuesto| repuesto.attributes.except("repuesto_catalogo_id") }

      expect {
        delete "/repuestos_catalogo/#{catalogo.id}", headers: auth_headers(admin)
      }.not_to change(Repuesto, :count)

      expect(response).to have_http_status(:no_content)
      repuestos.each_with_index do |repuesto, indice|
        expect(repuesto.reload.repuesto_catalogo_id).to be_nil
        expect(repuesto.attributes.except("repuesto_catalogo_id")).to eq(datos[indice])
      end
      expect(orden_abierta.reload).to be_abierta
      expect(orden_cerrada.reload).to be_cerrada
    end

    it "permite volver a cargar el nombre eliminado" do
      delete "/repuestos_catalogo/#{catalogo.id}", headers: auth_headers(admin)
      post "/repuestos_catalogo", params: { repuesto_catalogo: { nombre: catalogo.nombre, precio: "150" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["id"]).not_to eq(catalogo.id)
    end

    it "devuelve 404 para un artículo inexistente" do
      delete "/repuestos_catalogo/0", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  [ :post, :patch, :delete ].each do |metodo|
    it "exige autenticación para #{metodo} del catálogo" do
      ruta = metodo == :post ? "/repuestos_catalogo" : "/repuestos_catalogo/#{catalogo.id}"
      public_send(metodo, ruta, params: { repuesto_catalogo: { nombre: "Filtro", precio: "100" } }, as: :json)

      expect(response).to have_http_status(:unauthorized)
      expect(RepuestoCatalogo.exists?(catalogo.id)).to be(true) if metodo == :delete
    end

    it "prohíbe a mecánicos #{metodo} del catálogo" do
      ruta = metodo == :post ? "/repuestos_catalogo" : "/repuestos_catalogo/#{catalogo.id}"
      public_send(metodo, ruta, params: { repuesto_catalogo: { nombre: "Filtro", precio: "100" } },
        headers: auth_headers(create(:usuario)), as: :json)

      expect(response).to have_http_status(:forbidden)
      expect(RepuestoCatalogo.exists?(catalogo.id)).to be(true) if metodo == :delete
    end
  end
end
