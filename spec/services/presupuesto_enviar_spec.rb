require "rails_helper"

RSpec.describe PresupuestoEnviar do
  let(:administrador) { create(:usuario, :administrador) }
  let(:orden) { create(:orden) }
  let(:aseguradora) { create(:aseguradora, :con_contacto) }

  before { create(:caso, orden: orden, aseguradora: aseguradora) }

  it "registra el envío por email al contacto de la aseguradora" do
    envio = described_class.call(orden: orden, medio: "email", enviado_por: administrador)

    expect(envio).to be_persisted
    expect(envio.medio).to eq("email")
    expect(envio.destinatario).to eq(aseguradora.email)
    expect(envio.aseguradora).to eq(aseguradora)
    expect(envio.enviado_por).to eq(administrador)
    expect(envio.enviado_en).to be_within(2.seconds).of(Time.current)
  end

  it "registra el envío por WhatsApp con el teléfono de la aseguradora" do
    envio = described_class.call(orden: orden, medio: "whatsapp", enviado_por: administrador)

    expect(envio.medio).to eq("whatsapp")
    expect(envio.destinatario).to eq(aseguradora.telefono)
  end

  it "rechaza el envío si la orden no está vinculada a un caso" do
    orden_sin_caso = create(:orden)

    expect {
      described_class.call(orden: orden_sin_caso, medio: "email", enviado_por: administrador)
    }.to raise_error(ActiveRecord::RecordInvalid, /no está vinculada a un caso/)
  end

  it "rechaza el envío si la aseguradora no tiene el contacto del medio" do
    aseguradora.update!(email: nil)

    expect {
      described_class.call(orden: orden, medio: "email", enviado_por: administrador)
    }.to raise_error(ActiveRecord::RecordInvalid, /no tiene cargado el contacto/)
  end

  it "rechaza el envío si la orden está cerrada" do
    orden.update!(estado: :cerrada, cerrada_en: Time.current, cerrada_por: administrador, total_cerrado: 0)

    expect {
      described_class.call(orden: orden, medio: "email", enviado_por: administrador)
    }.to raise_error(ActiveRecord::RecordInvalid, /solo se calcula en órdenes abiertas/)
  end
end
