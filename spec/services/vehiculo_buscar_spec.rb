require "rails_helper"

RSpec.describe VehiculoBuscar do
  let(:ana) { create(:cliente, nombre: "Ana Gómez", telefono: "1145551234") }
  let(:bruno) { create(:cliente, nombre: "Bruno Díaz", telefono: "1166667777") }

  it "devuelve todos los vehículos ordenados por patente sin término" do
    create(:vehiculo, patente: "BB222BB")
    create(:vehiculo, patente: "AA111AA")

    expect(described_class.call(nil).pluck(:patente)).to eq(%w[AA111AA BB222BB])
  end

  it "busca por patente sin importar mayúsculas, espacios ni guiones" do
    buscado = create(:vehiculo, patente: "AB123CD")
    create(:vehiculo, patente: "ZZ999ZZ")

    expect(described_class.call("ab 123-cd")).to eq([ buscado ])
  end

  it "busca por una parte de la patente" do
    buscado = create(:vehiculo, patente: "AB123CD")
    create(:vehiculo, patente: "ZZ999ZZ")

    expect(described_class.call("123")).to eq([ buscado ])
  end

  it "prioriza la coincidencia exacta de la patente, luego las que empiezan igual" do
    contiene = create(:vehiculo, patente: "XAB123")
    empieza = create(:vehiculo, patente: "AB1234")
    exacta = create(:vehiculo, patente: "AB123")

    expect(described_class.call("ab123")).to eq([ exacta, empieza, contiene ])
  end

  it "busca por el nombre del dueño sin importar mayúsculas" do
    buscado = create(:vehiculo, cliente: ana)
    create(:vehiculo, cliente: bruno)

    expect(described_class.call("gómez")).to eq([ buscado ])
  end

  it "busca por el teléfono del dueño aunque tenga otro formato" do
    buscado = create(:vehiculo, cliente: ana)
    create(:vehiculo, cliente: bruno)

    expect(described_class.call("4555-1234")).to eq([ buscado ])
  end

  it "trata los comodines del término como texto" do
    create(:vehiculo, cliente: ana)

    expect(described_class.call("%")).to be_empty
  end

  it "respeta el alcance recibido" do
    propio = create(:vehiculo, patente: "AB123CD", cliente: ana)
    create(:vehiculo, patente: "AB123CE", cliente: bruno)

    expect(described_class.call("AB123", scope: Vehiculo.where(cliente: ana))).to eq([ propio ])
  end
end
