require "rails_helper"

RSpec.describe OrdenAbrir do
  let(:vehiculo) { create(:vehiculo) }

  it "abre una orden asociada al vehículo y a su dueño" do
    orden = described_class.call(vehiculo_id: vehiculo.id, motivo: "Ruido al frenar")

    expect(orden).to be_persisted
    expect(orden.vehiculo).to eq(vehiculo)
    expect(orden.cliente).to eq(vehiculo.cliente)
  end

  it "la orden nace abierta" do
    orden = described_class.call(vehiculo_id: vehiculo.id, motivo: "Ruido al frenar")

    expect(orden).to be_abierta
  end

  it "registra la fecha y hora de ingreso" do
    freeze_time do
      orden = described_class.call(vehiculo_id: vehiculo.id, motivo: "Ruido al frenar")

      expect(orden.created_at).to eq(Time.current)
    end
  end

  it "registra el motivo declarado por el cliente" do
    orden = described_class.call(vehiculo_id: vehiculo.id, motivo: "  Pierde aceite y hace ruido al frenar  ")

    expect(orden.reload.motivo).to eq("Pierde aceite y hace ruido al frenar")
  end

  it "conserva el cliente de la orden si el vehículo cambia de dueño" do
    duenio = vehiculo.cliente
    orden = described_class.call(vehiculo_id: vehiculo.id, motivo: "Service")

    VehiculoCambiarDuenio.call(vehiculo: vehiculo, cliente_id: create(:cliente).id)

    expect(orden.reload.cliente).to eq(duenio)
  end

  it "rechaza un vehículo inexistente" do
    expect {
      described_class.call(vehiculo_id: 0, motivo: "Ruido al frenar")
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:vehiculo]).to include("debe existir")
    }
    expect(Orden.count).to eq(0)
  end

  it "rechaza un motivo en blanco" do
    expect {
      described_class.call(vehiculo_id: vehiculo.id, motivo: "   ")
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:motivo]).to include("no puede estar en blanco")
    }
    expect(Orden.count).to eq(0)
  end
end
