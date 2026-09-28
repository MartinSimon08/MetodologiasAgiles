require "rails_helper"

RSpec.describe RepuestoAgregar do
  let(:orden) { create(:orden) }
  let(:admin) { create(:usuario, :administrador) }

  def agregar(**atributos)
    described_class.call(orden: orden, registrado_por: admin, descripcion: "Filtro de aceite",
                         cantidad: 2, costo_unitario: "100.50", **atributos)
  end

  it "registra una compra y la incorpora al catálogo con el margen del taller" do
    ConfiguracionTaller.actual.update!(margen_repuestos: "30.25")

    repuesto = agregar(proveedor: "Repuestos Centro")

    expect(repuesto).to be_persisted
    expect(repuesto).to have_attributes(orden: orden, registrado_por: admin, proveedor: "Repuestos Centro")
    expect(repuesto.precio_cliente).to eq(BigDecimal("261.80"))
    expect(repuesto.repuesto_catalogo).to have_attributes(nombre: "filtro de aceite", ultimo_costo: BigDecimal("100.50"))
  end

  it "usa el nombre del catálogo y el costo real enviado, conservando las compras anteriores" do
    anterior = agregar
    catalogo = anterior.repuesto_catalogo

    nueva = agregar(repuesto_catalogo_id: catalogo.id, descripcion: "Ignorada", costo_unitario: "120.75", margen: "10")

    expect(nueva.descripcion).to eq(catalogo.nombre)
    expect(nueva.precio_cliente).to eq(BigDecimal("265.65"))
    expect(catalogo.reload.ultimo_costo).to eq(BigDecimal("120.75"))
    expect(anterior.reload.costo_unitario).to eq(BigDecimal("100.50"))
    expect(anterior.precio_cliente).to eq(BigDecimal("201.00"))
    expect(RepuestoCatalogo.count).to eq(1)
  end

  it "reutiliza el catálogo aunque cambien las mayúsculas o los espacios" do
    agregar

    expect { agregar(descripcion: "  FILTRO   de aceite  ", costo_unitario: "90") }
      .not_to change(RepuestoCatalogo, :count)

    expect(RepuestoCatalogo.first.ultimo_costo).to eq(BigDecimal("90"))
  end

  it "acepta un costo cero y un margen explícito de cero" do
    ConfiguracionTaller.actual.update!(margen_repuestos: 30)

    repuesto = agregar(costo_unitario: "0", margen: "0")

    expect(repuesto.precio_cliente).to eq(0)
    expect(repuesto.margen).to eq(0)
    expect(repuesto.repuesto_catalogo.ultimo_costo).to eq(0)
  end

  it "exige el costo real aunque el catálogo tenga un costo sugerido" do
    catalogo = create(:repuesto_catalogo)

    expect { agregar(repuesto_catalogo_id: catalogo.id, costo_unitario: nil) }
      .to raise_error(ActiveRecord::RecordInvalid)

    expect(catalogo.reload.ultimo_costo).to eq(BigDecimal("100.50"))
    expect(Repuesto.count).to eq(0)
  end

  it "rechaza órdenes cerradas sin modificar el catálogo" do
    catalogo = create(:repuesto_catalogo)
    orden.update!(estado: :cerrada)

    expect { agregar(repuesto_catalogo_id: catalogo.id, costo_unitario: "200") }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors).to have_key(:orden) }

    expect(catalogo.reload.ultimo_costo).to eq(BigDecimal("100.50"))
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

  it "revierte la compra si falla la actualización del último costo" do
    catalogo = create(:repuesto_catalogo)
    allow(RepuestoCatalogo).to receive(:find).with(catalogo.id).and_return(catalogo)
    allow(catalogo).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(catalogo))

    expect { agregar(repuesto_catalogo_id: catalogo.id) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(Repuesto.count).to eq(0)
    expect(catalogo.reload.ultimo_costo).to eq(BigDecimal("100.50"))
  end
end
