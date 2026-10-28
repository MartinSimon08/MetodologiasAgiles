require "rails_helper"

RSpec.describe AseguradoraCambiarEstado do
  it "desactiva una aseguradora sin borrarla" do
    aseguradora = create(:aseguradora)

    described_class.call(aseguradora: aseguradora, activa: false)

    expect(aseguradora.reload).not_to be_activa
    expect(Aseguradora.exists?(aseguradora.id)).to be(true)
  end

  it "reactiva una aseguradora desactivada" do
    aseguradora = create(:aseguradora, :desactivada)

    described_class.call(aseguradora: aseguradora, activa: true)

    expect(aseguradora.reload).to be_activa
  end

  it "rechaza desactivar una aseguradora ya desactivada" do
    aseguradora = create(:aseguradora, :desactivada)

    expect {
      described_class.call(aseguradora: aseguradora, activa: false)
    }.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors.details[:base]).to include(error: :ya_desactivada) }
  end

  it "rechaza activar una aseguradora ya activa" do
    aseguradora = create(:aseguradora)

    expect {
      described_class.call(aseguradora: aseguradora, activa: true)
    }.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors.details[:base]).to include(error: :ya_activa) }
  end
end
