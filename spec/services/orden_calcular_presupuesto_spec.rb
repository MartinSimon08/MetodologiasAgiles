require "rails_helper"

RSpec.describe OrdenCalcularPresupuesto do
  let(:orden) { create(:orden) }
  let(:admin) { create(:usuario, :administrador) }

  it "presupuesta lo cargado y deja afuera del total lo rechazado" do
    create(:tarea, orden: orden, descripcion: "Alineación", precio: 8_000)
    create(:tarea, :terminada, orden: orden, descripcion: "Balanceo", precio: 2_000, aprobacion: :rechazada)
    create(:tarea, orden: orden, descripcion: "Sin precio", precio: nil)
    create(:tarea, orden: orden, descripcion: "Descartada", precio: 9_000, estado: :cancelada)
    RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1,
                         costo_unitario: "1000", margen: 50)
    rechazado = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Pastilla", cantidad: 1,
                                     costo_unitario: "400", margen: 0)
    RepuestoRegistrarAprobacion.call(repuesto: rechazado, aprobacion: "rechazado")
    RepuestoAvisar.call(orden: orden, registrado_por: create(:usuario), descripcion: "Correa", cantidad: 1)

    presupuesto = described_class.call(orden: orden.reload)

    expect(presupuesto.tareas.map(&:descripcion)).to contain_exactly("Alineación", "Balanceo", "Sin precio")
    expect(presupuesto.tareas.map(&:aprobacion)).to include("rechazada")
    expect(presupuesto.repuestos.map(&:descripcion)).to contain_exactly("Filtro", "Pastilla", "Correa")
    expect(presupuesto.presupuesto).to eq(11_900)
    expect(presupuesto.total_aseguradora).to eq(9_500)
  end

  it "rechaza el presupuesto de una orden que no está abierta" do
    orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { described_class.call(orden: orden) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
