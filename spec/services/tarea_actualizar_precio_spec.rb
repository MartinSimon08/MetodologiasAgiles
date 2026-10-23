require "rails_helper"

RSpec.describe TareaActualizarPrecio do
  it "fija el precio de una tarea pendiente" do
    tarea = create(:tarea, precio: nil)

    described_class.call(tarea: tarea, precio: 15_000)

    expect(tarea.reload.precio).to eq(15_000)
  end

  it "permite corregir el precio de una tarea ya terminada" do
    tarea = create(:tarea, :terminada, precio: 10_000)

    described_class.call(tarea: tarea, precio: 12_000)

    expect(tarea.reload.precio).to eq(12_000)
  end

  it "permite dejar el precio en $0" do
    tarea = create(:tarea, precio: 15_000)

    described_class.call(tarea: tarea, precio: 0)

    expect(tarea.reload.precio).to eq(0)
  end

  it "rechaza actualizar el precio de una tarea en una orden cerrada" do
    tarea = create(:tarea, :terminada)
    marcar_cerrada(tarea.orden)

    expect { described_class.call(tarea: tarea, precio: 15_000) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza actualizar el precio de una tarea en una orden cancelada" do
    tarea = create(:tarea)
    tarea.orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { described_class.call(tarea: tarea, precio: 15_000) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza un precio negativo" do
    tarea = create(:tarea)

    expect { described_class.call(tarea: tarea, precio: -1) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
