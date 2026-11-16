require "rails_helper"

RSpec.describe VehiculoHistorial do
  let(:vehiculo) { create(:vehiculo) }
  let(:administrador) { create(:usuario, :administrador) }

  def cerrar(orden)
    OrdenCerrar.call(orden: orden.reload, cerrada_por: administrador, descartar_pendientes: true)
  end

  def agregar_repuesto(orden, descripcion: "Filtro de aceite", costo_unitario: "1000", margen: 50)
    RepuestoAgregar.call(orden: orden, registrado_por: administrador, descripcion: descripcion,
                         cantidad: 1, costo_unitario: costo_unitario, margen: margen)
  end

  describe ".call" do
    it "lista solo las órdenes cerradas del vehículo, de la más reciente a la más antigua" do
      vieja = create(:orden, vehiculo: vehiculo)
      travel_to(2.days.ago) { cerrar(vieja) }
      nueva = create(:orden, vehiculo: vehiculo)
      cerrar(nueva)
      create(:orden, vehiculo: vehiculo)
      create(:orden, :cancelada, vehiculo: vehiculo)
      cerrar(create(:orden))

      expect(described_class.call(vehiculo: vehiculo).to_a).to eq([ nueva, vieja ])
    end
  end

  describe ".detallar" do
    let(:orden) { create(:orden, vehiculo: vehiculo) }

    it "incluye solo las tareas terminadas y no rechazadas, con sus mecánicos sin repetir" do
      juan = create(:usuario, nombre: "Juan")
      pedro = create(:usuario, nombre: "Pedro")
      cambio = create(:tarea, :terminada, orden: orden, descripcion: "Cambio de aceite", mecanico: juan)
      frenos = create(:tarea, :terminada, orden: orden, descripcion: "Frenos", mecanico: pedro)
      luces = create(:tarea, :terminada, orden: orden, descripcion: "Luces", mecanico: juan)
      create(:tarea, :terminada, :rechazada, orden: orden, mecanico: create(:usuario))
      create(:tarea, orden: orden)
      cerrar(orden)

      entrada = described_class.detallar(described_class.call(vehiculo: vehiculo).first)

      expect(entrada.tareas).to eq([ cambio, frenos, luces ])
      expect(entrada.mecanicos).to eq([ juan, pedro ])
    end

    it "incluye los repuestos cobrados y descarta los quitados o rechazados" do
      filtro = agregar_repuesto(orden)
      quitado = agregar_repuesto(orden, descripcion: "Filtro de aire")
      RepuestoQuitar.call(repuesto: quitado, quitado_por: administrador)
      rechazado = agregar_repuesto(orden, descripcion: "Bujía")
      RepuestoRegistrarAprobacion.call(repuesto: rechazado, aprobacion: :rechazado)
      cerrar(orden)

      entrada = described_class.detallar(described_class.call(vehiculo: vehiculo).first)

      expect(entrada.repuestos).to eq([ filtro ])
    end
  end
end
