require "rails_helper"

RSpec.describe TareaCrear do
  let(:orden) { create(:orden) }

  it "crea una tarea pendiente en la orden" do
    tarea = described_class.call(orden: orden, descripcion: "Cambiar aceite")

    expect(tarea).to be_persisted
    expect(tarea).to be_pendiente
    expect(tarea.orden).to eq(orden)
  end

  it "acepta un precio sugerido por el catálogo" do
    tarea = described_class.call(orden: orden, descripcion: "Cambiar aceite", precio: 15_000)

    expect(tarea.precio).to eq(15_000)
  end

  it "rechaza una descripción vacía" do
    expect { described_class.call(orden: orden, descripcion: "") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza crear tareas en una orden cerrada" do
    marcar_cerrada(orden)

    expect { described_class.call(orden: orden, descripcion: "Cambiar aceite") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "transmite la tarea nueva a los mecánicos conectados" do
    expect {
      described_class.call(orden: orden, descripcion: "Cambiar aceite")
    }.to have_broadcasted_to(TareasChannel::STREAM).with(
      hash_including("descripcion" => "Cambiar aceite", "orden_id" => orden.id)
    )
  end

  it "no transmite nada si la creación falla" do
    expect {
      expect { described_class.call(orden: orden, descripcion: "") }.to raise_error(ActiveRecord::RecordInvalid)
    }.not_to have_broadcasted_to(TareasChannel::STREAM)
  end
end
