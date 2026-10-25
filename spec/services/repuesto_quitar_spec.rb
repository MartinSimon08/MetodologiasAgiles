require "rails_helper"

RSpec.describe RepuestoQuitar do
  let(:orden) { create(:orden) }
  let(:admin) { create(:usuario, :administrador) }

  def agregar(**atributos)
    RepuestoAgregar.call(
      orden: orden, registrado_por: admin, descripcion: "Filtro de aceite",
      cantidad: 2, costo_unitario: "100.50", margen: "20", **atributos
    )
  end

  it "registra la baja y deja de sumar el repuesto al total" do
    vigente = agregar(descripcion: "Bujía", costo_unitario: "50", cantidad: 1, margen: "20")
    repuesto = agregar

    baja = described_class.call(repuesto: repuesto, quitado_por: admin)

    expect(baja.quitado_por).to eq(admin)
    expect(baja.quitado_en).to be_within(2.seconds).of(Time.current)
    expect(baja).to have_attributes(descripcion: "Filtro de aceite", cantidad: 2, precio_cliente: BigDecimal("241.20"))
    expect(Repuesto.exists?(repuesto.id)).to be true
    expect(orden.reload.total).to eq(vigente.precio_cliente)
    expect(orden.repuestos.vigentes).to contain_exactly(vigente)
    expect(orden.repuestos.quitados).to contain_exactly(repuesto)
  end

  it "al quitar un repuesto deja fuera también sus devoluciones" do
    otro = agregar(descripcion: "Bujía", costo_unitario: "50", cantidad: 1, margen: "0")
    repuesto = agregar(costo_unitario: "100", cantidad: 2, margen: "0")
    RepuestoRegistrarAjuste.call(
      repuesto: repuesto, registrado_por: admin, tipo: "devolucion", cantidad: 1,
      costo_unitario: "100", motivo: "Falla"
    )

    described_class.call(repuesto: repuesto, quitado_por: admin)

    expect(orden.reload.total).to eq(otro.precio_cliente)
    expect(repuesto.reload.ajustes.count).to eq(1)
  end

  it "permite quitar un aviso pendiente y después cerrar la orden" do
    pendiente = RepuestoAvisar.call(orden: orden, registrado_por: create(:usuario), descripcion: "Filtro", cantidad: 1)

    described_class.call(repuesto: pendiente, quitado_por: admin)

    expect(pendiente.reload).to be_pendiente_de_valorizar
    expect(pendiente.quitado_en).to be_present
    expect(orden.update(estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin,
                        total_cerrado: orden.total_a_cobrar)).to be true
  end

  it "rechaza la baja cuando los adelantos superarían el total" do
    repuesto = agregar
    create(:adelanto, orden: orden, importe: "200", registrado_por: admin)

    expect { described_class.call(repuesto: repuesto, quitado_por: admin) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:base]).to include(
          "El nuevo total quedaría por debajo de los adelantos ya registrados"
        )
      }

    expect(repuesto.reload.quitado_en).to be_nil
    expect(orden.reload.total).to eq(BigDecimal("241.20"))
  end

  it "permite la baja cuando la mano de obra sigue cubriendo los adelantos" do
    repuesto = agregar
    create(:adelanto, orden: orden, importe: "200", registrado_por: admin)
    create(:tarea, orden: orden, precio: "200")

    described_class.call(repuesto: repuesto, quitado_por: admin)

    expect(repuesto.reload.quitado_en).to be_present
    expect(orden.reload.total).to eq(BigDecimal("200"))
  end

  it "rechaza una orden cerrada" do
    repuesto = agregar
    marcar_cerrada(orden)

    expect { described_class.call(repuesto: repuesto, quitado_por: admin) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:orden]).to include("está cerrada") }

    expect(repuesto.reload.quitado_en).to be_nil
  end

  it "rechaza una orden cancelada" do
    repuesto = agregar
    orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { described_class.call(repuesto: repuesto, quitado_por: admin) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:orden]).to include("está cancelada") }
  end

  it "no pisa la baja si otro request ya la registró" do
    repuesto = agregar
    copia = Repuesto.find(repuesto.id)
    otro = create(:usuario, :administrador)

    described_class.call(repuesto: repuesto, quitado_por: admin)

    expect { described_class.call(repuesto: copia, quitado_por: otro) }
      .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:estado]).to include("ya fue quitado de la orden") }

    expect(repuesto.reload.quitado_por).to eq(admin)
  end

  it "la base rechaza una baja sin autor aunque se saltee la validación" do
    repuesto = agregar

    expect { repuesto.update_columns(quitado_en: Time.current) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
