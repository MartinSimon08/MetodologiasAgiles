require "rails_helper"

RSpec.describe MailPlantilla do
  let(:asegurado) { create(:cliente, nombre: "Juan <b>Pérez</b>") }
  let(:vehiculo) { create(:vehiculo, cliente: asegurado, patente: "AB123CD", marca: "Fiat", modelo: "Uno") }
  let(:caso) { create(:caso, asegurado: asegurado, vehiculo: vehiculo, numero_siniestro: "SIN-9") }

  describe ".aviso_asegurado" do
    subject(:html) { described_class.aviso_asegurado(caso: caso, mensaje: "Pasá a retirar <hoy>") }

    it "muestra el título, la foto del taller y los datos del caso" do
      expect(html).to include("Tu vehículo está listo para retirar", "taller.jpg", "AB123CD", "Fiat Uno", "SIN-9")
    end

    it "escapa el contenido que viene de datos y mensajes" do
      expect(html).to include("Juan &lt;b&gt;Pérez&lt;/b&gt;", "Pasá a retirar &lt;hoy&gt;")
      expect(html).not_to include("<b>Pérez</b>", "<hoy>")
    end

    it "permite cambiar el título" do
      expect(described_class.aviso_asegurado(caso: caso, mensaje: "x", titulo: "Novedades")).to include("Novedades")
    end
  end

  describe ".presupuesto" do
    it "lista las tareas y muestra el total para la aseguradora" do
      orden = create(:orden, cliente: asegurado, vehiculo: vehiculo)
      create(:tarea, orden: orden, descripcion: "Cambio de aceite", precio: 15_000)
      caso.update!(orden: orden)

      html = described_class.presupuesto(orden: orden, caso: caso, presupuesto: OrdenCalcularPresupuesto.call(orden: orden))

      expect(html).to include("Presupuesto de la orden ##{orden.id}", "Cambio de aceite", "$ 15.000,00", "Total para la aseguradora")
    end
  end

  describe ".imagen_url" do
    it "usa el dominio del taller por defecto y se puede cambiar por entorno" do
      expect(described_class.imagen_url).to eq("https://taller.onlineturnos.ar/mail/taller.jpg")

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("MAIL_IMAGENES_URL").and_return("https://cdn.ejemplo.com/img")
      expect(described_class.imagen_url).to eq("https://cdn.ejemplo.com/img/taller.jpg")
    end
  end
end
