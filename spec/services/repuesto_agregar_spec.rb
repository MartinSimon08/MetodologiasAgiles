require "rails_helper"

RSpec.describe RepuestoAgregar do
  let(:orden) { create(:orden) }
  let(:admin) { create(:usuario, :administrador) }

  def agregar(**atributos)
    described_class.call(orden: orden, registrado_por: admin, descripcion: "Filtro de aceite",
                         cantidad: 2, costo_unitario: "100.50", **atributos)
  end

  it "registra una compra ocasional con el margen del taller sin incorporarla al catálogo" do
    ConfiguracionTaller.actual.update!(margen_repuestos: "30.25")

    repuesto = agregar(proveedor: "Repuestos Centro")

    expect(repuesto).to be_persisted
    expect(repuesto).to have_attributes(orden: orden, registrado_por: admin, proveedor: "Repuestos Centro")
    expect(repuesto.precio_cliente).to eq(BigDecimal("261.80"))
    expect(repuesto.repuesto_catalogo).to be_nil
    expect(RepuestoCatalogo.count).to eq(0)
  end

  it "usa el nombre del catálogo y el costo real enviado, conservando las compras anteriores" do
    catalogo = create(:repuesto_catalogo, nombre: "Filtro de aceite")
    anterior = agregar(repuesto_catalogo_id: catalogo.id)

    nueva = agregar(repuesto_catalogo_id: catalogo.id, descripcion: "Ignorada", costo_unitario: "120.75", margen: "10")

    expect(nueva.descripcion).to eq(catalogo.nombre)
    expect(nueva.precio_cliente).to eq(BigDecimal("265.65"))
    expect(catalogo.reload.precio).to eq(BigDecimal("100.50"))
    expect(anterior.reload.costo_unitario).to eq(BigDecimal("100.50"))
    expect(anterior.precio_cliente).to eq(BigDecimal("201.00"))
    expect(RepuestoCatalogo.count).to eq(1)
  end

  it "conserva los datos de la compra cuando se edita el catálogo" do
    catalogo = create(:repuesto_catalogo, nombre: "Filtro de aceite")
    repuesto = agregar(repuesto_catalogo_id: catalogo.id)

    RepuestoCatalogoGuardar.call(repuesto: catalogo, nombre: "Filtro actualizado", precio: "200")

    expect(repuesto.reload).to have_attributes(descripcion: "filtro de aceite", costo_unitario: BigDecimal("100.50"),
                                             precio_cliente: BigDecimal("201.00"))
  end

  it "acepta un costo cero y un margen explícito de cero" do
    ConfiguracionTaller.actual.update!(margen_repuestos: 30)

    repuesto = agregar(costo_unitario: "0", margen: "0")

    expect(repuesto.precio_cliente).to eq(0)
    expect(repuesto.margen).to eq(0)
    expect(RepuestoCatalogo.count).to eq(0)
  end

  it "exige el costo real aunque el catálogo tenga un costo sugerido" do
    catalogo = create(:repuesto_catalogo)

    expect { agregar(repuesto_catalogo_id: catalogo.id, costo_unitario: nil) }
      .to raise_error(ActiveRecord::RecordInvalid)

    expect(catalogo.reload.precio).to eq(BigDecimal("100.50"))
    expect(Repuesto.count).to eq(0)
  end

  it "rechaza órdenes cerradas sin modificar el catálogo" do
    catalogo = create(:repuesto_catalogo)
    orden.update!(estado: :cerrada)

    expect { agregar(repuesto_catalogo_id: catalogo.id, costo_unitario: "200") }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors).to have_key(:orden) }

    expect(catalogo.reload.precio).to eq(BigDecimal("100.50"))
    expect(Repuesto.count).to eq(0)
  end

  [ { cantidad: 0 }, { cantidad: -1 }, { cantidad: "1.5" }, { cantidad: "abc" },
    { cantidad: nil }, { costo_unitario: "-1" }, { costo_unitario: "abc" },
    { costo_unitario: "10000000000" }, { margen: "-1" }, { margen: "101" },
    { margen: "abc" }, { descripcion: "   " }, { descripcion: "a" * 201 } ].each do |atributos|
    it "rechaza datos inválidos #{atributos.inspect} sin crear una compra ni un artículo" do
      expect { agregar(**atributos) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Repuesto.count).to eq(0)
      expect(RepuestoCatalogo.count).to eq(0)
    end
  end

  it "permite reutilizar un artículo sin consumir existencias ni modificarlo" do
    catalogo = create(:repuesto_catalogo)

    expect {
      2.times { agregar(repuesto_catalogo_id: catalogo.id, cantidad: 100, costo_unitario: "90") }
    }.not_to change { catalogo.reload.attributes }

    expect(Repuesto.count).to eq(2)
  end
end
