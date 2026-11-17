require "rails_helper"

RSpec.describe OrdenBuscar do
  let(:ana) { create(:cliente, nombre: "Ana Gómez", telefono: "1145551234") }
  let(:bruno) { create(:cliente, nombre: "Bruno Díaz", telefono: "1166667777") }
  let(:fiesta) { create(:vehiculo, cliente: ana, patente: "AB123CD", marca: "Ford", modelo: "Fiesta") }
  let(:cronos) { create(:vehiculo, cliente: bruno, patente: "ZZ999ZZ", marca: "Fiat", modelo: "Cronos") }
  let!(:orden_ana) { create(:orden, vehiculo: fiesta) }
  let!(:orden_bruno) { create(:orden, vehiculo: cronos) }

  it "devuelve todas las órdenes sin término" do
    expect(described_class.call(nil)).to contain_exactly(orden_ana, orden_bruno)
  end

  it "busca por el nombre del cliente sin importar mayúsculas ni acentos" do
    expect(described_class.call("gomez")).to eq([ orden_ana ])
  end

  it "busca por la patente sin importar mayúsculas, espacios ni guiones" do
    expect(described_class.call("ab 123-cd")).to eq([ orden_ana ])
  end

  it "busca por marca o modelo del vehículo" do
    expect(described_class.call("cronos")).to eq([ orden_bruno ])
    expect(described_class.call("fiat cronos")).to eq([ orden_bruno ])
  end

  it "busca por el teléfono del cliente" do
    expect(described_class.call("6666")).to eq([ orden_bruno ])
  end

  it "respeta el alcance recibido" do
    cerrada = create(:orden, :cerrada, vehiculo: fiesta)

    expect(described_class.call("ana", scope: Orden.cerrada)).to eq([ cerrada ])
  end

  it "no devuelve nada si no hay coincidencias" do
    expect(described_class.call("inexistente")).to be_empty
  end
end
