require "rails_helper"

RSpec.describe TareaLiberar do
  let(:tarea) { create(:tarea, :en_curso) }

  it "vuelve la tarea a pendiente y libera al mecánico" do
    described_class.call(tarea: tarea)

    tarea.reload
    expect(tarea).to be_pendiente
    expect(tarea.mecanico).to be_nil
    expect(tarea.tomada_en).to be_nil
  end

  it "rechaza liberar una tarea pendiente" do
    tarea = create(:tarea)

    expect { described_class.call(tarea: tarea) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza liberar una tarea ya terminada" do
    tarea = create(:tarea, :terminada)

    expect { described_class.call(tarea: tarea) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "permite que otro mecánico la tome después de liberada" do
    otro_mecanico = create(:usuario)
    described_class.call(tarea: tarea)

    TareaTomar.call(tarea: tarea, mecanico: otro_mecanico)

    expect(tarea.reload.mecanico).to eq(otro_mecanico)
  end
end
