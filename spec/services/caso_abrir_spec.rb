require "rails_helper"

RSpec.describe CasoAbrir do
  let(:aseguradora) { create(:aseguradora) }
  let(:vehiculo) { create(:vehiculo) }

  def abrir(**atributos)
    described_class.call(aseguradora_id: aseguradora.id, asegurado_id: vehiculo.cliente_id, vehiculo_id: vehiculo.id,
                         numero_siniestro: "SIN-1", **atributos)
  end

  it "abre un caso sin turno y sin orden" do
    caso = abrir(descripcion: "Choque trasero")

    expect(caso).to be_persisted
    expect(caso).to have_attributes(aseguradora: aseguradora, asegurado: vehiculo.cliente, vehiculo: vehiculo,
                                    numero_siniestro: "SIN-1", descripcion: "Choque trasero",
                                    fecha_turno: nil, orden: nil)
  end

  it "informa el número duplicado cuando la base de datos lo rechaza" do
    abrir
    allow_any_instance_of(Caso).to receive(:valid?).and_return(true)

    expect {
      abrir
    }.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors.details[:numero_siniestro]).to include(error: :taken) }
  end
end
