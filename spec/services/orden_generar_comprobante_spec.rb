require "rails_helper"

RSpec.describe OrdenGenerarComprobante do
  let(:orden) { create(:orden) }
  let(:administrador) { create(:usuario, :administrador) }
  let(:carlos) { create(:usuario, nombre: "Carlos") }

  def agregar_repuesto(descripcion: "Filtro de aceite", cantidad: 1, costo_unitario: "1000", margen: 50)
    RepuestoAgregar.call(orden: orden, registrado_por: administrador, descripcion: descripcion,
                         cantidad: cantidad, costo_unitario: costo_unitario, margen: margen)
  end

  def comprobante
    described_class.call(orden: orden.reload)
  end

  it "detalla el trabajo hecho y el total congelado" do
    create(:tarea, :terminada, orden: orden, descripcion: "Cambio de aceite", mecanico: carlos, precio: 15_000)
    agregar_repuesto(cantidad: 2)
    create(:adelanto, orden: orden, importe: "5000")
    marcar_cerrada(orden)

    resultado = comprobante

    expect(resultado.tareas.map(&:descripcion)).to eq([ "Cambio de aceite" ])
    expect(resultado.repuestos.map(&:descripcion)).to eq([ "Filtro de aceite" ])
    expect(resultado).to have_attributes(
      mano_de_obra: 15_000, total_repuestos: 3_000, total: 18_000, adelantado: 5_000, saldo: 13_000
    )
  end

  it "deja afuera del detalle las tareas sin terminar y las rechazadas" do
    create(:tarea, :terminada, orden: orden, descripcion: "Hecha", precio: 10_000)
    create(:tarea, orden: orden, descripcion: "Pendiente", precio: 4_000)
    create(:tarea, :terminada, orden: orden, descripcion: "Rechazada", precio: 6_000, aprobacion: :rechazada)
    create(:tarea, orden: orden, descripcion: "Descartada", precio: 9_000, estado: :cancelada)
    marcar_cerrada(orden)

    resultado = comprobante

    expect(resultado.tareas.map(&:descripcion)).to eq([ "Hecha" ])
    expect(resultado.mano_de_obra).to eq(10_000)
  end

  it "deja afuera del detalle los repuestos rechazados" do
    agregar_repuesto(descripcion: "Filtro")
    rechazado = agregar_repuesto(descripcion: "Pastilla")
    RepuestoRegistrarAprobacion.call(repuesto: rechazado, aprobacion: "rechazado")
    marcar_cerrada(orden)

    resultado = comprobante

    expect(resultado.repuestos.map(&:descripcion)).to eq([ "Filtro" ])
    expect(resultado.total_repuestos).to eq(1_500)
  end

  it "usa el total congelado al cerrar la orden" do
    create(:tarea, :terminada, orden: orden, precio: 12_000)
    marcar_cerrada(orden)

    expect(comprobante.total).to eq(12_000)
  end

  it "rechaza generar el comprobante de una orden abierta" do
    expect { described_class.call(orden: orden) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:base]).to include("El comprobante solo se genera a partir de una orden cerrada")
    }
  end

  it "rechaza generar el comprobante de una orden cancelada" do
    orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { described_class.call(orden: orden) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
