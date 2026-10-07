require "rails_helper"

RSpec.describe OrdenCancelar do
  let(:orden) { create(:orden, motivo: "Ruido al frenar") }
  let(:mecanico) { create(:usuario) }

  it "deja la orden identificada como cancelada con la fecha y hora" do
    freeze_time do
      resultado = described_class.call(orden: orden)

      expect(resultado.orden).to eq(orden)
      expect(orden.reload).to be_cancelada
      expect(orden.cancelada_en).to eq(Time.current)
    end
  end

  it "la distingue de una orden cerrada" do
    cerrada = create(:orden, :cerrada)

    described_class.call(orden: orden)

    expect(Orden.cancelada).to contain_exactly(orden)
    expect(Orden.cerrada).to contain_exactly(cerrada)
  end

  it "conserva los datos de la orden" do
    cliente = orden.cliente
    vehiculo = orden.vehiculo
    ingreso = orden.created_at

    described_class.call(orden: orden)

    expect(orden.reload).to have_attributes(cliente: cliente, vehiculo: vehiculo, motivo: "Ruido al frenar",
                                            created_at: ingreso)
  end

  it "conserva las tareas terminadas con su responsable, sus horarios y su precio" do
    terminada = create(:tarea, :terminada, orden: orden, mecanico: mecanico, precio: 15_000)
    antes = terminada.reload.attributes

    resultado = described_class.call(orden: orden)

    expect(resultado.tareas_liberadas).to be_empty
    expect(terminada.reload.attributes).to eq(antes)
  end

  it "conserva las tareas pendientes y los repuestos cargados" do
    pendiente = create(:tarea, orden: orden)
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: create(:usuario, :administrador),
                                    descripcion: "Filtro de aceite", cantidad: 1, costo_unitario: "100")

    described_class.call(orden: orden)

    expect(orden.tareas.reload).to contain_exactly(pendiente)
    expect(pendiente.reload).to be_pendiente
    expect(orden.repuestos.reload).to contain_exactly(repuesto)
  end

  it "libera las tareas en curso para que el mecánico quede disponible" do
    en_curso = create(:tarea, :en_curso, orden: orden, mecanico: mecanico)
    de_otra_orden = create(:tarea, :en_curso, mecanico: mecanico)

    resultado = described_class.call(orden: orden)

    expect(resultado.tareas_liberadas).to contain_exactly(en_curso)
    expect(en_curso.reload).to have_attributes(estado: "pendiente", mecanico: nil, tomada_en: nil)
    expect(de_otra_orden.reload).to be_en_curso
  end

  it "permite abrir una orden nueva para el mismo vehículo" do
    described_class.call(orden: orden)

    nueva = OrdenAbrir.call(vehiculo_id: orden.vehiculo_id, motivo: "Service")

    expect(nueva).to be_abierta
    expect(orden.reload).to be_cancelada
  end

  it "rechaza cancelar una orden que ya está cancelada sin cambiar la fecha" do
    cancelada = create(:orden, :cancelada, cancelada_en: 2.days.ago)
    fecha = cancelada.reload.cancelada_en

    expect { described_class.call(orden: cancelada) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:base]).to include("La orden ya está cancelada")
    }
    expect(cancelada.reload.cancelada_en).to eq(fecha)
  end

  it "rechaza cancelar una orden cerrada" do
    cerrada = create(:orden, :cerrada)

    expect { described_class.call(orden: cerrada) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:base]).to include("No se puede cancelar una orden cerrada")
    }
    expect(cerrada.reload).to be_cerrada
  end

  context "con la orden ya cancelada" do
    let!(:pendiente) { create(:tarea, orden: orden) }

    before { described_class.call(orden: orden) }

    it "no permite tomar sus tareas" do
      expect { TareaTomar.call(tarea: pendiente, mecanico: mecanico) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:orden]).to include("está cancelada")
      }
      expect(pendiente.reload).to be_pendiente
    end

    it "no permite cargarle tareas nuevas" do
      expect { TareaCrear.call(orden: orden, descripcion: "Cambiar aceite") }.to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:orden]).to include("está cancelada")
      }
    end

    it "no permite cargarle repuestos nuevos" do
      expect {
        RepuestoAgregar.call(orden: orden, registrado_por: create(:usuario, :administrador),
                             descripcion: "Filtro de aceite", cantidad: 1, costo_unitario: "100")
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Repuesto.where(orden: orden)).to be_empty
    end
  end

  context "con dos conexiones reales a la base" do
    self.use_transactional_tests = false

    after do
      Tarea.delete_all
      Orden.delete_all
      Vehiculo.delete_all
      Cliente.delete_all
      Usuario.delete_all
    end

    it "no deja una tarea en curso si un mecánico la toma mientras se cancela la orden" do
      orden = create(:orden)
      tarea = create(:tarea, orden: orden)
      mecanico = create(:usuario)

      hilos = [
        -> { described_class.call(orden: Orden.find(orden.id)) },
        -> { TareaTomar.call(tarea: Tarea.find(tarea.id), mecanico: mecanico) }
      ].map do |accion|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            accion.call
          rescue ActiveRecord::RecordInvalid
            nil
          end
        end
      end
      hilos.each(&:join)

      expect(orden.reload).to be_cancelada
      expect(tarea.reload).to have_attributes(estado: "pendiente", mecanico: nil)
    end
  end
end
