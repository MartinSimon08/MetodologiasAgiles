require "rails_helper"

RSpec.describe ConfiguracionTaller, type: :model do
  it "crea una única configuración del taller" do
    configuracion = described_class.actual

    expect(described_class.actual).to eq(configuracion)
    expect(described_class.count).to eq(1)
  end

  it "usa cero como margen inicial" do
    expect(described_class.actual.margen_repuestos).to eq(0)
  end

  it "acepta un margen entre cero y cien" do
    expect(described_class.new(margen_repuestos: 25.5)).to be_valid
  end

  it "rechaza un margen negativo" do
    expect(described_class.new(margen_repuestos: -0.01)).not_to be_valid
  end

  it "rechaza un margen mayor a cien" do
    expect(described_class.new(margen_repuestos: 100.01)).not_to be_valid
  end
end
