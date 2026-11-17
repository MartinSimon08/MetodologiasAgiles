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
