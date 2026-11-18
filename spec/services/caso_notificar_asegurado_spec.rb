require "rails_helper"

RSpec.describe CasoNotificarAsegurado do
  it "registra una notificación por telegram al asegurado del caso" do
    asegurado = create(:cliente, nombre: "Juan Pérez", telefono: "1122334455")
    caso = create(:caso, asegurado: asegurado, numero_siniestro: "SIN-1")

    allow(TelegramEnviar).to receive(:call).and_return(true)

    expect { described_class.call(caso: caso) }.to change(NotificacionAsegurado, :count).by(1)

    notificacion = NotificacionAsegurado.last
    expect(notificacion.caso).to eq(caso)
    expect(notificacion).to be_telegram
    expect(notificacion.enviada_en).to be_within(2.seconds).of(Time.current)
  end

  it "avisa también por mail cuando el asegurado tiene email" do
    asegurado = create(:cliente, email: "juan@ejemplo.com")
    caso = create(:caso, asegurado: asegurado, numero_siniestro: "SIN-2")
    allow(TelegramEnviar).to receive(:call).and_return(true)
    allow(EmailEnviar).to receive(:call).and_return(true)

    expect { described_class.call(caso: caso) }.to change(NotificacionAsegurado, :count).by(2)

    expect(EmailEnviar).to have_received(:call).with(
      destinatario: "juan@ejemplo.com", asunto: "Aviso del taller - Caso SIN-2", texto: /ya está listo para retirar/,
      html: a_string_including("Tu vehículo está listo para retirar", "SIN-2")
    )
    expect(caso.notificacion_asegurados.pluck(:medio)).to contain_exactly("telegram", "email")
  end

  it "no registra el aviso por mail si el envío falla" do
    caso = create(:caso, asegurado: create(:cliente, email: "juan@ejemplo.com"))
    allow(TelegramEnviar).to receive(:call).and_return(true)
    allow(EmailEnviar).to receive(:call).and_return(false)

    expect { described_class.call(caso: caso) }.to change(NotificacionAsegurado, :count).by(1)
  end

  it "no manda mail si el asegurado no tiene email" do
    caso = create(:caso, asegurado: create(:cliente, email: nil))
    allow(TelegramEnviar).to receive(:call).and_return(true)
    allow(EmailEnviar).to receive(:call)

    described_class.call(caso: caso)

    expect(EmailEnviar).not_to have_received(:call)
  end

  it "arma el mensaje con el nombre del asegurado, la patente y el caso" do
    asegurado = create(:cliente, nombre: "Juan Pérez")
    vehiculo = create(:vehiculo, cliente: asegurado, patente: "AB123CD")
    caso = create(:caso, asegurado: asegurado, vehiculo: vehiculo, numero_siniestro: "SIN-1")

    notificacion = described_class.call(caso: caso)

    expect(notificacion.contenido).to include("Juan Pérez")
    expect(notificacion.contenido).to include("AB123CD")
    expect(notificacion.contenido).to include("SIN-1")
    expect(notificacion.contenido).to include(caso.aseguradora.nombre)
  end
end
