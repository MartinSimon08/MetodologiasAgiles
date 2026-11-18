require "rails_helper"

RSpec.describe OrdenAvisarCierre do
  let(:cliente) { create(:cliente, email: "cliente@ejemplo.com") }
  let(:vehiculo) { create(:vehiculo, cliente: cliente) }
  let(:orden) { create(:orden, :cerrada, cliente: cliente, vehiculo: vehiculo) }

  before do
    allow(EmailEnviar).to receive(:call).and_return(true)
    allow(TelegramEnviar).to receive(:call).and_return(true)
  end

  it "ofrece los avisos del cliente cuando la orden no tiene caso" do
    expect(described_class.destinos(orden).pluck(:destino)).to eq(%w[cliente_listo cliente_total])
  end

  it "avisa al cliente que retire el vehículo" do
    described_class.call(orden: orden, destino: "cliente_listo")

    expect(EmailEnviar).to have_received(:call).with(
      destinatario: "cliente@ejemplo.com", asunto: /listo para retirar/, texto: /#{vehiculo.patente}/,
      html: a_string_including(vehiculo.patente)
    )
  end

  it "envía el total al cliente" do
    described_class.call(orden: orden, destino: "cliente_total")

    expect(EmailEnviar).to have_received(:call).with(hash_including(texto: /Total: \$ 0/, html: a_string_including("Total")))
  end

  it "rechaza el aviso si el cliente no tiene email" do
    cliente.update!(email: nil)

    expect { described_class.call(orden: orden, destino: "cliente_listo") }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza una orden abierta" do
    abierta = create(:orden, cliente: cliente, vehiculo: vehiculo)

    expect { described_class.call(orden: abierta, destino: "cliente_listo") }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context "con un caso vinculado" do
    let(:aseguradora) { create(:aseguradora, email: "seguros@ejemplo.com") }
    let!(:caso) { create(:caso, orden: orden, asegurado: cliente, vehiculo: vehiculo, aseguradora: aseguradora) }

    it "ofrece los avisos a la aseguradora y al asegurado" do
      expect(described_class.destinos(orden).pluck(:destino)).to eq(%w[aseguradora asegurado])
    end

    it "avisa a la aseguradora el cierre con el total a facturar" do
      described_class.call(orden: orden, destino: "aseguradora")

      expect(EmailEnviar).to have_received(:call).with(
        destinatario: "seguros@ejemplo.com", asunto: /cerrada/, texto: /Total a facturar/,
        html: a_string_including("Total a facturar", caso.numero_siniestro)
      )
    end

    it "avisa al asegurado" do
      expect { described_class.call(orden: orden, destino: "asegurado") }.to change(NotificacionAsegurado, :count).by(2)
    end

    it "no acepta los avisos de cliente común" do
      expect { described_class.call(orden: orden, destino: "cliente_listo") }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
