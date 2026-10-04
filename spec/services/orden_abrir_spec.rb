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

  it "rechaza abrir otra orden si el vehículo ya tiene una abierta" do
    described_class.call(vehiculo_id: vehiculo.id, motivo: "Ruido al frenar")

    expect {
      described_class.call(vehiculo_id: vehiculo.id, motivo: "Pierde aceite")
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:vehiculo]).to include("ya tiene una orden abierta")
    }
    expect(Orden.count).to eq(1)
  end

  it "permite abrir una orden nueva cuando la anterior del vehículo ya se cerró" do
    described_class.call(vehiculo_id: vehiculo.id, motivo: "Ruido al frenar").update!(estado: :cerrada)

    orden = described_class.call(vehiculo_id: vehiculo.id, motivo: "Pierde aceite")

    expect(orden).to be_abierta
    expect(Orden.where(vehiculo: vehiculo).count).to eq(2)
  end

  it "permite tener órdenes abiertas para vehículos distintos" do
    described_class.call(vehiculo_id: vehiculo.id, motivo: "Ruido al frenar")

    expect(described_class.call(vehiculo_id: create(:vehiculo).id, motivo: "Service")).to be_persisted
  end

  context "con dos conexiones reales a la base" do
    self.use_transactional_tests = false

    after do
      Orden.delete_all
      Vehiculo.delete_all
      Cliente.delete_all
    end

    it "impide que dos pedidos simultáneos abran dos órdenes para el mismo vehículo" do
      vehiculo = create(:vehiculo)
      resultados = Queue.new

      hilos = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            described_class.call(vehiculo_id: vehiculo.id, motivo: "Ruido al frenar")
            resultados << :ok
          rescue ActiveRecord::RecordInvalid
            resultados << :rechazada
          end
        end
      end
      hilos.each(&:join)

      expect(Array.new(2) { resultados.pop }).to contain_exactly(:ok, :rechazada)
      expect(Orden.abierta.where(vehiculo: vehiculo).count).to eq(1)
    end
  end
end
