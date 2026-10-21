require "rails_helper"

RSpec.describe OrdenCerrar do
  let(:orden) { create(:orden) }
  let(:administrador) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  def agregar_repuesto(costo_unitario: "1000", margen: 50, cantidad: 1)
    RepuestoAgregar.call(orden: orden, registrado_por: administrador, descripcion: "Filtro de aceite",
                         cantidad: cantidad, costo_unitario: costo_unitario, margen: margen)
  end

  it "calcula el total con la mano de obra de las tareas terminadas y el precio de los repuestos" do
    create(:tarea, :terminada, orden: orden, precio: 15_000)
    create(:tarea, :terminada, orden: orden, precio: 5_000)
    agregar_repuesto(cantidad: 2)

    described_class.call(orden: orden, cerrada_por: administrador)

    expect(orden.reload).to be_cerrada
    expect(orden.total_cerrado).to eq(23_000)
  end

  it "registra quién cerró la orden y cuándo" do
    freeze_time do
      described_class.call(orden: orden, cerrada_por: administrador)

      expect(orden.reload).to have_attributes(cerrada_por: administrador, cerrada_en: Time.current)
    end
  end

  it "rechaza cerrar con tareas en curso" do
    en_curso = create(:tarea, :en_curso, orden: orden, mecanico: mecanico)

    expect { described_class.call(orden: orden, cerrada_por: administrador, descartar_pendientes: true) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include("No se puede cerrar la orden porque tiene tareas tomadas o en curso")
      }
    expect(orden.reload).to be_abierta
    expect(en_curso.reload).to be_en_curso
  end

  it "rechaza cerrar con tareas pendientes sin confirmar que se descartan" do
    pendiente = create(:tarea, orden: orden)

    expect { described_class.call(orden: orden, cerrada_por: administrador) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include(
          "Hay tareas pendientes sin tomar. Confirmá que se descartan para cerrar la orden"
        )
      }
    expect(orden.reload).to be_abierta
    expect(pendiente.reload).to be_pendiente
  end

  it "cancela las tareas pendientes confirmadas y no las cobra" do
    pendiente = create(:tarea, orden: orden, precio: 8_000)
    terminada = create(:tarea, :terminada, orden: orden, precio: 15_000)

    described_class.call(orden: orden, cerrada_por: administrador, descartar_pendientes: true)

    expect(pendiente.reload).to be_cancelada
    expect(terminada.reload).to be_terminada
    expect(orden.reload.total_cerrado).to eq(15_000)
  end

  it "rechaza cerrar con repuestos pendientes de valorizar" do
    RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Correa", cantidad: 1)

    expect { described_class.call(orden: orden, cerrada_por: administrador) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include("No se puede cerrar la orden porque tiene repuestos pendientes de valorizar")
      }
    expect(orden.reload).to be_abierta
  end

  it "informa todos los motivos que impiden el cierre a la vez" do
    create(:tarea, :en_curso, orden: orden)
    create(:tarea, orden: orden)
    RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Correa", cantidad: 1)

    expect { described_class.call(orden: orden, cerrada_por: administrador) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:base].size).to eq(3) }
  end

  it "rechaza cerrar una orden ya cerrada sin cambiar su cierre" do
    described_class.call(orden: orden, cerrada_por: administrador)
    cierre = orden.reload.slice(:cerrada_en, :cerrada_por_id, :total_cerrado)

    expect { described_class.call(orden: orden, cerrada_por: create(:usuario, :administrador)) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include("La orden ya está cerrada")
      }
    expect(orden.reload.slice(:cerrada_en, :cerrada_por_id, :total_cerrado)).to eq(cierre)
  end

  it "rechaza cerrar una orden cancelada" do
    cancelada = create(:orden, :cancelada)

    expect { described_class.call(orden: cancelada, cerrada_por: administrador) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include("No se puede cerrar una orden cancelada")
      }
    expect(cancelada.reload).to be_cancelada
  end

  context "con la orden ya cerrada" do
    let!(:terminada) { create(:tarea, :terminada, orden: orden, precio: 15_000) }
    let!(:repuesto) { agregar_repuesto }
    let!(:pendiente) { create(:tarea, orden: orden) }

    before { described_class.call(orden: orden, cerrada_por: administrador, descartar_pendientes: true) }

    it "mantiene el total aunque cambie el margen del taller" do
      ConfiguracionTallerActualizar.call(margen_repuestos: 90)

      expect(orden.reload.total).to eq(16_500)
    end

    it "mantiene el total aunque se modifique el precio de un repuesto" do
      repuesto.update_column(:precio_cliente, 99_999)

      expect(orden.reload.total).to eq(16_500)
    end

    it "no permite cargarle tareas nuevas" do
      expect { TareaCrear.call(orden: orden, descripcion: "Cambiar aceite") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:orden]).to include("está cerrada") }
    end

    it "no permite cargarle repuestos ni avisos de repuestos" do
      expect { agregar_repuesto }.to raise_error(ActiveRecord::RecordInvalid)
      expect { RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Correa", cantidad: 1) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect(orden.repuestos.reload).to contain_exactly(repuesto)
    end

    it "no permite tomar las tareas descartadas" do
      expect { TareaTomar.call(tarea: pendiente, mecanico: mecanico) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(pendiente.reload).to have_attributes(estado: "cancelada", mecanico: nil)
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

    it "no deja una tarea tomada en una orden cerrada si un mecánico la toma mientras se cierra" do
      orden = create(:orden)
      tarea = create(:tarea, orden: orden)
      administrador = create(:usuario, :administrador)
      mecanico = create(:usuario)

      hilos = [
        -> { described_class.call(orden: Orden.find(orden.id), cerrada_por: administrador, descartar_pendientes: true) },
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

      orden.reload
      tarea.reload
      if orden.cerrada?
        expect(tarea).to have_attributes(estado: "cancelada", mecanico: nil)
      else
        expect(tarea).to have_attributes(estado: "en_curso", mecanico: mecanico)
      end
    end
  end
end
