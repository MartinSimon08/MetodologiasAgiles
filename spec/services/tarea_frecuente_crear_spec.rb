require "rails_helper"

RSpec.describe TareaFrecuenteCrear do
  it "registra una tarea frecuente" do
    tarea_frecuente = described_class.call(descripcion: "Cambio de aceite", precio_sugerido: 15_000)

    expect(tarea_frecuente).to be_persisted
    expect(tarea_frecuente.precio_sugerido).to eq(15_000)
  end

  it "informa la descripción duplicada si otro registro gana la carrera" do
    create(:tarea_frecuente, descripcion: "Cambio de aceite")
    allow_any_instance_of(TareaFrecuente).to receive(:valid?).and_return(true)

    expect {
      described_class.call(descripcion: "Cambio de aceite", precio_sugerido: 15_000)
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:descripcion]).to include("ya está en uso")
    }
  end
end
