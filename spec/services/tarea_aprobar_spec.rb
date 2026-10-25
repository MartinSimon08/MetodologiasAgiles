require "rails_helper"

RSpec.describe TareaAprobar do
  it "aprueba una tarea pendiente" do
    tarea = create(:tarea)

    described_class.call(tarea: tarea)

    expect(tarea.reload).to be_aprobacion_aprobada
  end

  it "permite volver a aprobar una tarea que había sido rechazada" do
    tarea = create(:tarea, :rechazada)

    described_class.call(tarea: tarea)

    expect(tarea.reload).to be_aprobacion_aprobada
  end

  it "no cambia el estado de la tarea" do
    tarea = create(:tarea, :en_curso)

    described_class.call(tarea: tarea)

    expect(tarea.reload).to be_en_curso
  end

  it "rechaza aprobar una tarea de una orden cerrada" do
    tarea = create(:tarea, :terminada)
    marcar_cerrada(tarea.orden)

    expect { described_class.call(tarea: tarea) }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect(tarea.reload).to be_aprobacion_pendiente
  end

  it "rechaza aprobar una tarea de una orden cancelada" do
    tarea = create(:tarea)
    tarea.orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { described_class.call(tarea: tarea) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
