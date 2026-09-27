require "rails_helper"

RSpec.describe TareaCompletar do
  let(:tarea) { create(:tarea, :en_curso) }

  it "marca la tarea como terminada y registra el timestamp" do
    described_class.call(tarea: tarea)

    tarea.reload
    expect(tarea).to be_terminada
    expect(tarea.terminada_en).to be_within(2.seconds).of(Time.current)
  end

  it "conserva al mecánico responsable" do
    mecanico = tarea.mecanico

    described_class.call(tarea: tarea)

    expect(tarea.reload.mecanico).to eq(mecanico)
  end

  it "rechaza completar una tarea pendiente" do
    tarea = create(:tarea)

    expect { described_class.call(tarea: tarea) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza completar una tarea ya terminada" do
    tarea = create(:tarea, :terminada)

    expect { described_class.call(tarea: tarea) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
