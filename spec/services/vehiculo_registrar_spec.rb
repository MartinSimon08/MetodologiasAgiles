require "rails_helper"

RSpec.describe VehiculoRegistrar do
  let(:cliente) { create(:cliente) }

  it "registra un vehículo asociado al cliente" do
    vehiculo = described_class.call(cliente_id: cliente.id, patente: "AB123CD", marca: "Fiat", modelo: "Cronos",
                                    anio: 2021, kilometraje: 30_000)

    expect(vehiculo).to be_persisted
    expect(vehiculo.cliente).to eq(cliente)
  end

  it "informa la patente duplicada si otro registro gana la carrera" do
    create(:vehiculo, patente: "AB123CD")
    allow_any_instance_of(Vehiculo).to receive(:valid?).and_return(true)

    expect {
      described_class.call(cliente_id: cliente.id, patente: "AB123CD")
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:patente]).to include("ya está en uso")
    }
  end
end
