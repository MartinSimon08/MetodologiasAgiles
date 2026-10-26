require "rails_helper"

RSpec.describe RepuestoRegistrarAprobacion do
  let(:admin) { create(:usuario, :administrador) }

  it "marca un repuesto vigente como rechazado y lo saca del total" do
    orden = create(:orden)
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1,
                                    costo_unitario: "100", margen: 0)

    described_class.call(repuesto: repuesto, aprobacion: "rechazado")

    expect(repuesto.reload).to be_aprobacion_rechazado
    expect(orden.reload.total_repuestos).to eq(0)
    expect(orden.repuestos).to include(repuesto)
  end

  it "no deja rechazar un repuesto si el total quedaría bajo los adelantos" do
    orden = create(:orden)
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1,
                                    costo_unitario: "1500", margen: 0)
    create(:adelanto, orden: orden, importe: "1500", registrado_por: admin)

    expect { described_class.call(repuesto: repuesto, aprobacion: "rechazado") }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include(
          "El nuevo total quedaría por debajo de los adelantos ya registrados"
        )
      }

    expect(repuesto.reload).to be_aprobacion_pendiente
    expect(orden.reload.saldo).to eq(0)
  end

  it "permite rechazar el repuesto cuando la mano de obra sigue cubriendo los adelantos" do
    orden = create(:orden)
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1,
                                    costo_unitario: "1500", margen: 0)
    create(:tarea, orden: orden, precio: "1500")
    create(:adelanto, orden: orden, importe: "1500", registrado_por: admin)

    described_class.call(repuesto: repuesto, aprobacion: "rechazado")

    expect(repuesto.reload).to be_aprobacion_rechazado
    expect(orden.reload.total).to eq(1_500)
    expect(orden.saldo).to eq(0)
  end

  it "no deja decidir sobre un repuesto ya quitado" do
    orden = create(:orden)
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1,
                                    costo_unitario: "100", margen: 0)
    RepuestoQuitar.call(repuesto: repuesto, quitado_por: admin)

    expect { described_class.call(repuesto: repuesto, aprobacion: "rechazado") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
