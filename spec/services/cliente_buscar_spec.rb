require "rails_helper"

RSpec.describe ClienteBuscar do
  let!(:ana) { create(:cliente, nombre: "Ana Gómez", telefono: "1145551234") }
  let!(:bruno) { create(:cliente, nombre: "Bruno Díaz", telefono: "1166667777") }

  it "devuelve todos los clientes ordenados por nombre sin término" do
    expect(described_class.call("  ")).to eq([ ana, bruno ])
  end

  it "busca por una parte del nombre sin importar mayúsculas" do
    expect(described_class.call("GÓM")).to eq([ ana ])
  end

  it "busca por teléfono aunque tenga otro formato" do
    expect(described_class.call("11 6666-7777")).to eq([ bruno ])
  end

  it "busca por la patente de alguno de sus vehículos" do
    create(:vehiculo, patente: "AB123CD", cliente: bruno)
    create(:vehiculo, patente: "ZZ999ZZ", cliente: bruno)

    expect(described_class.call("ab 123 cd")).to eq([ bruno ])
  end

  it "prioriza al dueño de la patente exacta" do
    create(:vehiculo, patente: "AB1234", cliente: ana)
    create(:vehiculo, patente: "AB123", cliente: bruno)

    expect(described_class.call("AB123")).to eq([ bruno, ana ])
  end

  it "prioriza la coincidencia exacta del teléfono" do
    abel = create(:cliente, nombre: "Abel Ruiz", telefono: "111145551234")

    expect(described_class.call("1145551234")).to eq([ ana, abel ])
    expect(described_class.call("111145551234")).to eq([ abel ])
  end

  it "no devuelve resultados si nada coincide" do
    expect(described_class.call("Zoe")).to be_empty
  end
end
