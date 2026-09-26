require "rails_helper"

RSpec.describe ClienteRegistrar do
  it "registra un cliente sin email" do
    cliente = described_class.call(nombre: "Ana Gómez", telefono: "1145551234")

    expect(cliente).to be_persisted
    expect(cliente.email).to be_nil
  end

  it "informa el teléfono duplicado si otro registro gana la carrera" do
    create(:cliente, telefono: "1145551234")
    allow_any_instance_of(Cliente).to receive(:valid?).and_return(true)

    expect {
      described_class.call(nombre: "Ana Gómez", telefono: "1145551234")
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:telefono]).to include("ya está en uso")
    }
  end
end
