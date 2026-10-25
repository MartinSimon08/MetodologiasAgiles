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

  it "no deja decidir sobre un repuesto ya quitado" do
    orden = create(:orden)
    repuesto = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1,
                                    costo_unitario: "100", margen: 0)
    RepuestoQuitar.call(repuesto: repuesto, quitado_por: admin)

    expect { described_class.call(repuesto: repuesto, aprobacion: "rechazado") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
