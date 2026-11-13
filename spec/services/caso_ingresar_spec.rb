require "rails_helper"

RSpec.describe CasoIngresar do
  let(:asegurado) { create(:cliente) }
  let(:vehiculo) { create(:vehiculo, cliente: asegurado) }
  let(:caso) { create(:caso, asegurado: asegurado, vehiculo: vehiculo, descripcion: "Choque trasero", fecha_turno: Date.current) }

  it "abre una orden con el asegurado, el vehículo y el motivo del caso y la vincula" do
    resultado = described_class.call(caso_id: caso.id)

    orden = resultado.orden
    expect(orden).to have_attributes(cliente: asegurado, vehiculo: vehiculo, motivo: "Choque trasero", estado: "abierta")
    expect(caso.reload.orden_id).to eq(orden.id)
  end

  it "usa el número de siniestro como motivo cuando el caso no tiene descripción" do
    caso.update!(descripcion: nil, numero_siniestro: "SIN-77")

    described_class.call(caso_id: caso.id)

    expect(caso.reload.orden.motivo).to eq("Siniestro SIN-77")
  end

  it "rechaza un caso sin turno" do
    caso.update!(fecha_turno: nil)

    expect { described_class.call(caso_id: caso.id) }.to raise_error(ActiveRecord::RecordInvalid, /no tiene turno/)
    expect(Orden.count).to eq(0)
    expect(caso.reload.orden_id).to be_nil
  end

  it "rechaza un caso que ya tiene orden" do
    described_class.call(caso_id: caso.id)

    expect { described_class.call(caso_id: caso.id) }.to raise_error(ActiveRecord::RecordInvalid, /ya tiene una orden/)
    expect(Orden.count).to eq(1)
  end

  it "no deja el caso ingresado si el vehículo ya tiene una orden abierta" do
    create(:orden, vehiculo: vehiculo, cliente: asegurado)

    expect { described_class.call(caso_id: caso.id) }.to raise_error(ActiveRecord::RecordInvalid, /ya tiene una orden abierta/)
    expect(caso.reload.orden_id).to be_nil
  end
end
