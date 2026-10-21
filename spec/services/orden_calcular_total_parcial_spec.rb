require "rails_helper"

RSpec.describe OrdenCalcularTotalParcial do
  let(:orden) { create(:orden) }
  let(:administrador) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  def agregar_repuesto(costo_unitario: "1000", margen: 50, cantidad: 1)
    RepuestoAgregar.call(orden: orden, registrado_por: administrador, descripcion: "Filtro de aceite",
                         cantidad: cantidad, costo_unitario: costo_unitario, margen: margen)
  end

  def total_parcial
    described_class.call(orden: orden.reload)
  end

  it "suma la mano de obra de todas las tareas cargadas y el precio de los repuestos valorizados" do
    create(:tarea, :terminada, orden: orden, precio: 15_000)
    create(:tarea, :en_curso, orden: orden, precio: 7_000)
    create(:tarea, orden: orden, precio: 3_000)
    create(:tarea, orden: orden, precio: nil)
    agregar_repuesto(cantidad: 2)

    expect(total_parcial).to have_attributes(mano_de_obra: 25_000, total_repuestos: 3_000, total: 28_000)
  end

  it "informa lo que se cobraría si se cerrara ahora" do
    create(:tarea, :terminada, orden: orden, precio: 15_000)
    create(:tarea, orden: orden, precio: 3_000)
    agregar_repuesto

    expect(total_parcial.a_cobrar_hoy).to eq(16_500)
  end

  it "ignora las tareas descartadas" do
    create(:tarea, orden: orden, precio: 5_000)
    create(:tarea, orden: orden, precio: 9_000, estado: :cancelada)

    parcial = total_parcial

    expect(parcial.total).to eq(5_000)
    expect(parcial.tareas.map(&:precio)).to eq([ 5_000 ])
  end

  it "lista los repuestos pendientes de valorizar sin sumarlos" do
    pendiente = RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Correa", cantidad: 1)

    parcial = total_parcial

    expect(parcial.repuestos).to eq([ pendiente ])
    expect(parcial.total).to eq(0)
  end

  describe "recálculo" do
    it "suma una tarea recién agregada" do
      create(:tarea, orden: orden, precio: 5_000)
      expect { create(:tarea, orden: orden, precio: 2_500) }.to change { total_parcial.total }.from(5_000).to(7_500)
    end

    it "refleja el cambio de precio de una tarea" do
      tarea = create(:tarea, orden: orden, precio: 5_000)
      expect { tarea.update!(precio: 6_000) }.to change { total_parcial.total }.from(5_000).to(6_000)
    end

    it "resta una tarea quitada" do
      tarea = create(:tarea, orden: orden, precio: 5_000)
      expect { tarea.destroy! }.to change { total_parcial.total }.from(5_000).to(0)
    end

    it "suma un repuesto recién agregado" do
      expect { agregar_repuesto }.to change { total_parcial.total }.from(0).to(1_500)
    end

    it "suma un repuesto cuando se valoriza" do
      pendiente = RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Correa", cantidad: 2)

      expect { RepuestoValorizar.call(repuesto: pendiente, costo_unitario: "1000", margen: 10) }
        .to change { total_parcial.total }.from(0).to(2_200)
    end

    it "refleja el cambio de precio de un repuesto" do
      repuesto = agregar_repuesto
      expect { repuesto.update!(precio_cliente: 2_000) }.to change { total_parcial.total }.from(1_500).to(2_000)
    end

    it "resta un repuesto quitado" do
      repuesto = agregar_repuesto
      expect { repuesto.destroy! }.to change { total_parcial.total }.from(1_500).to(0)
    end
  end

  it "rechaza calcularlo en una orden cerrada" do
    marcar_cerrada(orden)

    expect { described_class.call(orden: orden) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:base]).to include("El total parcial solo se calcula en órdenes abiertas")
    }
  end

  it "rechaza calcularlo en una orden cancelada" do
    orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { described_class.call(orden: orden) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
