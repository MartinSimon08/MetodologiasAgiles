require "rails_helper"

RSpec.describe CasoAvisarListoParaRetirar do
  it "avisa a recepción cuando todas las tareas de la orden del caso están terminadas" do
    orden = create(:orden)
    caso = create(:caso, orden: orden)
    create(:tarea, :terminada, orden: orden)

    expect {
      described_class.call(orden: orden)
    }.to have_broadcasted_to(RecepcionChannel::STREAM).with(
      hash_including(
        "tipo" => "caso_listo_para_retirar",
        "caso_id" => caso.id,
        "numero_siniestro" => caso.numero_siniestro,
        "orden_id" => orden.id,
        "aseguradora" => hash_including("nombre" => caso.aseguradora.nombre)
      )
    )
  end

  it "incluye el vehículo de la orden en el aviso" do
    orden = create(:orden)
    create(:caso, orden: orden)
    create(:tarea, :terminada, orden: orden)

    expect {
      described_class.call(orden: orden)
    }.to have_broadcasted_to(RecepcionChannel::STREAM).with(
      hash_including("vehiculo" => hash_including("patente" => orden.vehiculo.patente))
    )
  end

  it "no avisa si todavía queda una tarea pendiente o en curso" do
    orden = create(:orden)
    create(:caso, orden: orden)
    create(:tarea, :terminada, orden: orden)
    create(:tarea, orden: orden)

    expect {
      described_class.call(orden: orden)
    }.not_to have_broadcasted_to(RecepcionChannel::STREAM)
  end

  it "no avisa si la orden no está vinculada a un caso" do
    orden = create(:orden)
    create(:tarea, :terminada, orden: orden)

    expect {
      described_class.call(orden: orden)
    }.not_to have_broadcasted_to(RecepcionChannel::STREAM)
  end

  it "no avisa si la orden no tiene tareas" do
    orden = create(:orden)
    create(:caso, orden: orden)

    expect {
      described_class.call(orden: orden)
    }.not_to have_broadcasted_to(RecepcionChannel::STREAM)
  end

  it "no avisa si la orden ya está cerrada" do
    orden = create(:orden)
    create(:caso, orden: orden)
    create(:tarea, :terminada, orden: orden)
    orden.update!(estado: :cerrada, cerrada_en: Time.current,
                  cerrada_por: create(:usuario, :administrador), total_cerrado: 0)

    expect {
      described_class.call(orden: orden)
    }.not_to have_broadcasted_to(RecepcionChannel::STREAM)
  end
end
