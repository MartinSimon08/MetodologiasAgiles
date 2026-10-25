require "rails_helper"

RSpec.describe RepuestoEditar do
  let(:orden) { create(:orden) }
  let(:admin) { create(:usuario, :administrador) }

  def agregar(**atributos)
    RepuestoAgregar.call(
      orden: orden, registrado_por: admin, descripcion: "Filtro de aceite",
      cantidad: 2, costo_unitario: "100.50", margen: "20", proveedor: "Casa Central", **atributos
    )
  end

  def editar(repuesto, **atributos)
    described_class.call(repuesto: repuesto, atributos: atributos)
  end

  it "recalcula el precio al cambiar la cantidad y conserva el margen y la descripción" do
    repuesto = agregar
    catalogo = create(:repuesto_catalogo, nombre: "Filtro de aceite")
    repuesto.update!(repuesto_catalogo: catalogo)

    corregido = editar(repuesto, cantidad: 3)

    expect(corregido.precio_cliente).to eq(BigDecimal("361.80"))
    expect(corregido).to have_attributes(
      cantidad: 3, margen: BigDecimal("20"), costo_unitario: BigDecimal("100.50"),
      descripcion: "Filtro de aceite", proveedor: "Casa Central", registrado_por: admin,
      repuesto_catalogo: catalogo, estado: "valorizado"
    )
    expect(catalogo.reload.precio).to eq(BigDecimal("100.50"))
  end

  it "recalcula el precio al cambiar costo, margen o proveedor" do
    repuesto = agregar

    corregido = editar(repuesto, costo_unitario: "80", margen: "10", proveedor: "  Casa   Norte  ")

    expect(corregido.precio_cliente).to eq(BigDecimal("176.00"))
    expect(corregido).to have_attributes(margen: BigDecimal("10"), proveedor: "Casa Norte", cantidad: 2)
  end

  it "conserva el margen de la compra cuando no se envía uno" do
    ConfiguracionTaller.actual.update!(margen_repuestos: "30.25")
    repuesto = agregar

    corregido = editar(repuesto, cantidad: 1)

    expect(corregido.margen).to eq(BigDecimal("20"))
    expect(corregido.precio_cliente).to eq(BigDecimal("120.60"))
    expect(ConfiguracionTaller.actual.margen_repuestos).to eq(BigDecimal("30.25"))
  end

  it "acepta costo cero, margen cero y un proveedor en blanco" do
    repuesto = agregar

    corregido = editar(repuesto, costo_unitario: "0", margen: "0", proveedor: "   ")

    expect(corregido.precio_cliente).to eq(0)
    expect(corregido.margen).to eq(0)
    expect(corregido.proveedor).to be_nil
  end

  it "no modifica otra compra de la misma orden" do
    repuesto = agregar
    otra = agregar(descripcion: "Bujía", costo_unitario: "50", cantidad: 1)

    editar(repuesto, cantidad: 4)

    expect(otra.reload).to have_attributes(cantidad: 1, precio_cliente: BigDecimal("60.00"))
    expect(orden.reload.total).to eq(BigDecimal("542.40"))
  end

  it "corrige cantidad y proveedor de un repuesto pendiente sin valorizarlo" do
    pendiente = RepuestoAvisar.call(orden: orden, registrado_por: create(:usuario), descripcion: "Filtro", cantidad: 1)

    corregido = editar(pendiente, cantidad: 3, proveedor: "Casa Norte")

    expect(corregido).to have_attributes(cantidad: 3, proveedor: "Casa Norte", estado: "pendiente_de_valorizar",
                                        costo_unitario: nil, margen: nil, precio_cliente: nil)
  end

  it "rechaza cargar costo o margen sobre un repuesto pendiente" do
    pendiente = RepuestoAvisar.call(orden: orden, registrado_por: create(:usuario), descripcion: "Filtro", cantidad: 1)

    expect { editar(pendiente, costo_unitario: "80", margen: "10") }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors).to have_key(:base) }

    expect(pendiente.reload).to be_pendiente_de_valorizar
  end

  it "rechaza la corrección cuando el total quedaría por debajo de los adelantos" do
    repuesto = agregar
    create(:adelanto, orden: orden, importe: "200", registrado_por: admin)

    expect { editar(repuesto, cantidad: 1) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include(
          "El nuevo total quedaría por debajo de los adelantos ya registrados"
        )
      }

    expect(repuesto.reload).to have_attributes(cantidad: 2, precio_cliente: BigDecimal("241.20"))
  end

  it "permite la corrección cuando el total sigue cubriendo los adelantos" do
    repuesto = agregar
    create(:adelanto, orden: orden, importe: "200", registrado_por: admin)

    corregido = editar(repuesto, cantidad: 3)

    expect(corregido.precio_cliente).to eq(BigDecimal("361.80"))
  end

  it "rechaza una orden cerrada sin modificar la compra" do
    repuesto = agregar
    marcar_cerrada(orden)

    expect { editar(repuesto, cantidad: 4) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:orden]).to include("está cerrada") }

    expect(repuesto.reload.cantidad).to eq(2)
  end

  it "rechaza una orden cancelada" do
    repuesto = agregar
    orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { editar(repuesto, cantidad: 4) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:orden]).to include("está cancelada") }
  end

  it "rechaza corregir un repuesto ya quitado, también si otro request lo quitó antes" do
    repuesto = agregar
    copia = Repuesto.find(repuesto.id)
    RepuestoQuitar.call(repuesto: repuesto, quitado_por: admin)

    expect { editar(copia, cantidad: 4) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors).to have_key(:estado) }

    expect(repuesto.reload.cantidad).to eq(2)
  end

  [ { cantidad: 0 }, { cantidad: -1 }, { cantidad: "1.5" }, { costo_unitario: "-1" },
    { costo_unitario: "10000000000" }, { margen: "-1" }, { margen: "101" } ].each do |atributos|
    it "rechaza datos inválidos #{atributos.inspect} sin modificar la compra" do
      repuesto = agregar

      expect { editar(repuesto, **atributos) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(repuesto.reload).to have_attributes(cantidad: 2, precio_cliente: BigDecimal("241.20"))
    end
  end
end
