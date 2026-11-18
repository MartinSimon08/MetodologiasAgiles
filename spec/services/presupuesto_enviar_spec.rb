require "rails_helper"

RSpec.describe PresupuestoEnviar do
  let(:administrador) { create(:usuario, :administrador) }
  let(:orden) { create(:orden) }
  let(:aseguradora) { create(:aseguradora, :con_contacto, :con_telegram) }

  before { create(:caso, orden: orden, aseguradora: aseguradora) }

  it "registra el envío por email al contacto de la aseguradora" do
    allow(EmailEnviar).to receive(:call).and_return(true)

    envio = described_class.call(orden: orden, medio: "email", enviado_por: administrador)

    expect(envio).to be_persisted
    expect(envio.medio).to eq("email")
    expect(envio.destinatario).to eq(aseguradora.email)
    expect(envio.aseguradora).to eq(aseguradora)
    expect(envio.enviado_por).to eq(administrador)
    expect(envio.enviado_en).to be_within(2.seconds).of(Time.current)
    expect(EmailEnviar).to have_received(:call).with(
      destinatario: aseguradora.email, asunto: "Presupuesto orden ##{orden.id}", texto: /Presupuesto de la orden/,
      html: a_string_including("Presupuesto de la orden ##{orden.id}", "Total para la aseguradora")
    )
  end

  it "no registra el envío por email si el proveedor falla" do
    allow(EmailEnviar).to receive(:call).and_return(false)

    expect {
      described_class.call(orden: orden, medio: "email", enviado_por: administrador)
    }.to raise_error(ActiveRecord::RecordInvalid, /No se pudo enviar el presupuesto/)
    expect(EnvioPresupuesto.count).to eq(0)
  end

  it "registra el envío por Telegram al chat vinculado de la aseguradora" do
    allow(TelegramEnviar).to receive(:call).and_return(true)

    envio = described_class.call(orden: orden, medio: "telegram", enviado_por: administrador)

    expect(envio.medio).to eq("telegram")
    expect(envio.destinatario).to eq("555000111")
    expect(TelegramEnviar).to have_received(:call).with(
      texto: /Presupuesto de la orden ##{orden.id}/, chat_ids: [ "555000111" ]
    )
  end

  it "no registra el envío por Telegram si falla" do
    allow(TelegramEnviar).to receive(:call).and_return(false)

    expect {
      described_class.call(orden: orden, medio: "telegram", enviado_por: administrador)
    }.to raise_error(ActiveRecord::RecordInvalid, /No se pudo enviar el presupuesto/)
    expect(EnvioPresupuesto.count).to eq(0)
  end

  it "rechaza el envío por Telegram si la aseguradora no está vinculada" do
    aseguradora.update!(telegram_chat_id: nil)

    expect {
      described_class.call(orden: orden, medio: "telegram", enviado_por: administrador)
    }.to raise_error(ActiveRecord::RecordInvalid, /no está vinculada a Telegram/)
  end

  # it "registra el envío por WhatsApp con el teléfono de la aseguradora" do
  #   envio = described_class.call(orden: orden, medio: "whatsapp", enviado_por: administrador)
  #
  #   expect(envio.medio).to eq("whatsapp")
  #   expect(envio.destinatario).to eq(aseguradora.telefono)
  # end

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
