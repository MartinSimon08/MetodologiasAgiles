require "rails_helper"

RSpec.describe TareaRechazar do
  it "rechaza una tarea pendiente sin tocar su estado" do
    tarea = create(:tarea)

    described_class.call(tarea: tarea)

    tarea.reload
    expect(tarea).to be_aprobacion_rechazada
    expect(tarea).to be_pendiente
  end

  it "libera una tarea en curso, la marca rechazada y avisa al mecánico" do
    mecanico = create(:usuario)
    tarea = create(:tarea, :en_curso, mecanico: mecanico)

    expect {
      described_class.call(tarea: tarea)
    }.to have_broadcasted_to(mecanico).from_channel(TareasChannel).with(
      hash_including("tipo" => "tarea_rechazada", "id" => tarea.id, "orden_id" => tarea.orden_id)
    )

    tarea.reload
    expect(tarea).to be_pendiente
    expect(tarea).to be_aprobacion_rechazada
    expect(tarea.mecanico).to be_nil
    expect(tarea.tomada_en).to be_nil
  end

  it "no se puede volver a tomar una tarea en curso que fue rechazada" do
    mecanico = create(:usuario)
    tarea = create(:tarea, :en_curso, mecanico: mecanico)

    described_class.call(tarea: tarea)

    expect { TareaTomar.call(tarea: tarea.reload, mecanico: create(:usuario)) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "deja terminada y rechazada una tarea ya terminada, sin avisar a nadie" do
    mecanico = create(:usuario)
    tarea = create(:tarea, :terminada, mecanico: mecanico)

    expect {
      described_class.call(tarea: tarea)
    }.not_to have_broadcasted_to(mecanico).from_channel(TareasChannel)

    tarea.reload
    expect(tarea).to be_terminada
    expect(tarea).to be_aprobacion_rechazada
  end

  it "excluye del total autorizado a una tarea terminada que fue rechazada" do
    orden = create(:orden)
    create(:tarea, :terminada, orden: orden, precio: 10_000)
    rechazada = create(:tarea, :terminada, orden: orden, precio: 5_000)

    described_class.call(tarea: rechazada)

    expect(orden.reload.mano_de_obra).to eq(10_000)
  end

  it "rechaza rechazar una tarea de una orden cerrada" do
    tarea = create(:tarea, :terminada)
    marcar_cerrada(tarea.orden)

    expect { described_class.call(tarea: tarea) }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect(tarea.reload).to be_aprobacion_pendiente
  end
end
