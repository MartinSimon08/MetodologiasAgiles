require "rails_helper"

RSpec.describe RepuestoAvisar do
  let(:orden) { create(:orden) }
  let(:mecanico) { create(:usuario) }

  def avisar(**atributos)
    described_class.call(orden: orden, registrado_por: mecanico, descripcion: "Filtro de aceite", cantidad: 1, **atributos)
  end

  it "registra el aviso como pendiente de valorizar, sin costo ni margen ni precio" do
    repuesto = avisar

    expect(repuesto).to be_persisted
    expect(repuesto).to be_pendiente_de_valorizar
    expect(repuesto).to have_attributes(orden: orden, registrado_por: mecanico, descripcion: "Filtro de aceite", cantidad: 1,
                                        costo_unitario: nil, margen: nil, precio_cliente: nil)
  end

  it "rechaza avisos en órdenes cerradas" do
    orden.update!(estado: :cerrada)

    expect { avisar }.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors).to have_key(:orden) }
    expect(Repuesto.count).to eq(0)
  end

  [ { cantidad: 0 }, { cantidad: -1 }, { cantidad: "1.5" }, { cantidad: "abc" }, { cantidad: nil },
    { descripcion: "   " }, { descripcion: "a" * 201 }, { descripcion: nil } ].each do |atributos|
    it "rechaza datos inválidos #{atributos.inspect} sin crear un aviso" do
      expect { avisar(**atributos) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Repuesto.count).to eq(0)
    end
  end
end
