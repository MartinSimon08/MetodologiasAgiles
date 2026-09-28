require "rails_helper"

RSpec.describe VehiculoCambiarDuenio do
  let(:vehiculo) { create(:vehiculo) }
  let(:nuevo_duenio) { create(:cliente) }

  it "asigna el vehículo al nuevo dueño" do
    described_class.call(vehiculo: vehiculo, cliente_id: nuevo_duenio.id)

    expect(vehiculo.reload.cliente).to eq(nuevo_duenio)
  end

  it "deja al vehículo fuera de los vehículos del dueño anterior" do
    anterior = vehiculo.cliente

    described_class.call(vehiculo: vehiculo, cliente_id: nuevo_duenio.id)

    expect(anterior.vehiculos.reload).to be_empty
    expect(nuevo_duenio.vehiculos).to contain_exactly(vehiculo)
  end

  it "rechaza asignarlo al mismo dueño" do
    expect {
      described_class.call(vehiculo: vehiculo, cliente_id: vehiculo.cliente_id)
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:cliente]).to include("ya es el dueño de este vehículo")
    }
  end

  it "rechaza un cliente inexistente sin cambiar el dueño" do
    anterior = vehiculo.cliente

    expect {
      described_class.call(vehiculo: vehiculo, cliente_id: 0)
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(vehiculo.reload.cliente).to eq(anterior)
  end
end
