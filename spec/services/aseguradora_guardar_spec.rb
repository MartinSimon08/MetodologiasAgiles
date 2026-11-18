require "rails_helper"

RSpec.describe AseguradoraGuardar do
  it "crea una aseguradora con nombre y contacto" do
    aseguradora = described_class.call(nombre: "Sancor", telefono: "1145551234", email: "siniestros@sancor.test")

    expect(aseguradora).to be_persisted
    expect(aseguradora).to have_attributes(nombre: "Sancor", telefono: "1145551234", email: "siniestros@sancor.test", activa: true)
  end

  it "edita una aseguradora existente" do
    aseguradora = create(:aseguradora, :con_contacto)

    described_class.call(aseguradora: aseguradora, nombre: "Rivadavia", telefono: "", email: "")

    expect(aseguradora.reload).to have_attributes(nombre: "Rivadavia", telefono: nil, email: nil)
  end

  it "desvincula Telegram cuando cambia el teléfono" do
    aseguradora = create(:aseguradora, :con_telegram, telefono: "1145551234")

    described_class.call(aseguradora: aseguradora, telefono: "1166667777")

    expect(aseguradora.reload.telegram_chat_id).to be_nil
  end

  it "conserva el vínculo de Telegram si el teléfono no cambia" do
    aseguradora = create(:aseguradora, :con_telegram, telefono: "1145551234")

    described_class.call(aseguradora: aseguradora, nombre: "Nuevo nombre", telefono: "11 4555-1234")

    expect(aseguradora.reload.telegram_chat_id).to eq("555000111")
  end

  it "informa el nombre duplicado cuando la base de datos lo rechaza" do
    create(:aseguradora, nombre: "Sancor")
    allow_any_instance_of(Aseguradora).to receive(:valid?).and_return(true)

    expect {
      described_class.call(nombre: "SANCOR")
    }.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors.details[:nombre]).to include(error: :taken) }
  end
end
