require "rails_helper"

RSpec.describe RepuestoValorizar do
  let(:orden) { create(:orden) }
  let(:mecanico) { create(:usuario) }
  let(:repuesto) do
    RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Filtro de aceite", cantidad: 2)
  end

  it "carga el costo, calcula el precio al cliente y pasa el repuesto a valorizado" do
    valorizado = described_class.call(repuesto: repuesto, costo_unitario: "100.50", margen: "25")

    expect(valorizado).to be_valorizado
    expect(valorizado.costo_unitario).to eq(BigDecimal("100.50"))
    expect(valorizado.margen).to eq(BigDecimal("25"))
    expect(valorizado.precio_cliente).to eq(BigDecimal("251.25"))
  end

  it "usa el margen configurado en el taller si no se envía uno" do
    ConfiguracionTaller.actual.update!(margen_repuestos: "30.25")

    valorizado = described_class.call(repuesto: repuesto, costo_unitario: "100")

    expect(valorizado.margen).to eq(BigDecimal("30.25"))
    expect(valorizado.precio_cliente).to eq(BigDecimal("260.50"))
  end

  it "rechaza volver a valorizar un repuesto ya valorizado" do
    described_class.call(repuesto: repuesto, costo_unitario: "100")

    expect { described_class.call(repuesto: repuesto, costo_unitario: "120") }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors).to have_key(:estado) }
  end

  it "rechaza valorizar en una orden cerrada" do
    pendiente = repuesto
    orden.update_column(:estado, "cerrada")

    expect { described_class.call(repuesto: pendiente, costo_unitario: "100") }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors).to have_key(:orden) }
    expect(pendiente.reload).to be_pendiente_de_valorizar
  end

  [ { costo_unitario: nil }, { costo_unitario: "-1" }, { costo_unitario: "abc" },
    { costo_unitario: "10000000000" }, { costo_unitario: "100", margen: "-1" },
    { costo_unitario: "100", margen: "101" }, { costo_unitario: "100", margen: "abc" } ].each do |atributos|
    it "rechaza datos inválidos #{atributos.inspect} sin modificar el repuesto" do
      expect { described_class.call(repuesto: repuesto, **atributos) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(repuesto.reload).to be_pendiente_de_valorizar
    end
  end
end
