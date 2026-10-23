require "rails_helper"

RSpec.describe TareaNotaCrear do
  let(:tarea) { create(:tarea) }
  let(:mecanico) { create(:usuario) }

  it "crea una nota asociada a la tarea" do
    nota = described_class.call(tarea: tarea, registrado_por: mecanico, contenido: "Falta repuesto")

    expect(nota).to be_persisted
    expect(nota.tarea).to eq(tarea)
    expect(nota.registrado_por).to eq(mecanico)
    expect(nota.contenido).to eq("Falta repuesto")
  end

  it "conserva las notas anteriores en vez de sobrescribirlas" do
    described_class.call(tarea: tarea, registrado_por: mecanico, contenido: "Primera nota")
    described_class.call(tarea: tarea, registrado_por: create(:usuario), contenido: "Segunda nota")

    expect(tarea.notas.reload.pluck(:contenido)).to contain_exactly("Primera nota", "Segunda nota")
  end

  it "rechaza un contenido vacío" do
    expect { described_class.call(tarea: tarea, registrado_por: mecanico, contenido: "") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza agregar una nota a una tarea de una orden cerrada" do
    marcar_cerrada(tarea.orden)

    expect { described_class.call(tarea: tarea, registrado_por: mecanico, contenido: "Nota") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza agregar una nota a una tarea de una orden cancelada" do
    tarea.orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { described_class.call(tarea: tarea, registrado_por: mecanico, contenido: "Nota") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
