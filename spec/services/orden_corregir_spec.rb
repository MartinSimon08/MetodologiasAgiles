require "rails_helper"

RSpec.describe OrdenCorregir do
  let(:administrador) { create(:usuario, :administrador) }
  let(:orden) { create(:orden, :cerrada, total_cerrado: 15_000) }

  def corregir(**opciones)
    described_class.call(orden: orden, usuario: administrador, motivo: "Se cargó mal el precio", **opciones)
  end

  it "corrige el total y deja la auditoría con valor anterior, valor nuevo, usuario, motivo y fecha" do
    freeze_time do
      corregir(total_cerrado: "12000")

      expect(orden.reload.total_cerrado).to eq(12_000)
      expect(orden.correcciones.sole).to have_attributes(
        campo: "total_cerrado", valor_anterior: 15_000, valor_nuevo: 12_000, usuario: administrador,
        motivo: "Se cargó mal el precio", created_at: Time.current, revision_confirmada: false
      )
    end
  end

  it "registra una corrección por cada campo cambiado" do
    corregir(total_cerrado: "12000", franquicia: "2000")

    expect(orden.reload).to have_attributes(total_cerrado: 12_000, franquicia: 2_000)
    expect(orden.correcciones.pluck(:campo)).to contain_exactly("total_cerrado", "franquicia")
  end

  it "permite quitar la franquicia" do
    orden.update!(franquicia: 1_000)

    corregir(franquicia: "", confirmar_revision: true)

    expect(orden.reload.franquicia).to be_nil
    expect(orden.correcciones.sole).to have_attributes(valor_anterior: 1_000, valor_nuevo: nil)
  end

  it "exige un motivo" do
    expect { described_class.call(orden: orden, usuario: administrador, motivo: "  ", total_cerrado: "1") }
      .to raise_error(ActiveRecord::RecordInvalid, /Motivo de la corrección no puede estar en blanco/)
    expect(orden.reload.total_cerrado).to eq(15_000)
    expect(CorreccionOrden.count).to eq(0)
  end

  it "rechaza una corrección que no cambia nada" do
    expect { corregir(total_cerrado: "15000") }.to raise_error(ActiveRecord::RecordInvalid, /no cambia ningún valor/)
    expect(CorreccionOrden.count).to eq(0)
  end

  it "rechaza una corrección sin campos" do
    expect { corregir }.to raise_error(ActiveRecord::RecordInvalid, /no cambia ningún valor/)
  end

  it "solo corrige órdenes cerradas" do
    abierta = create(:orden)

    expect { described_class.call(orden: abierta, usuario: administrador, motivo: "x", total_cerrado: "1") }
      .to raise_error(ActiveRecord::RecordInvalid, /Solo se puede corregir una orden cerrada/)
  end

  it "rechaza montos inválidos" do
    expect { corregir(total_cerrado: "abc") }.to raise_error(ActiveRecord::RecordInvalid, /Total al cierre/)
    expect { corregir(total_cerrado: "-5") }.to raise_error(ActiveRecord::RecordInvalid)
    expect(orden.reload.total_cerrado).to eq(15_000)
  end

  it "rechaza una franquicia mayor al nuevo total" do
    expect { corregir(total_cerrado: "1000", franquicia: "2000") }
      .to raise_error(ActiveRecord::RecordInvalid, /Franquicia del asegurado no puede ser mayor/)
  end

  it "rechaza un total menor a los adelantos registrados" do
    adelantada = create(:orden, :cerrada, total_cerrado: 15_000)
    build(:adelanto, orden: adelantada, importe: 9_000).save!(validate: false)

    expect do
      described_class.call(orden: adelantada, usuario: administrador, motivo: "x", total_cerrado: "8000")
    end.to raise_error(ActiveRecord::RecordInvalid, /no puede ser menor a los adelantos/)
  end

  describe "revisión de la franquicia y del saldo a facturar" do
    it "exige confirmar la revisión si la franquicia ya se cobró" do
      orden.update!(franquicia: 1_000)

      expect { corregir(total_cerrado: "12000") }.to raise_error(ActiveRecord::RecordInvalid, /Confirmá que los revisaste/)
      expect(orden.reload.total_cerrado).to eq(15_000)
    end

    it "exige confirmar la revisión si la orden tiene caso con saldo para la aseguradora" do
      create(:caso, orden: orden, vehiculo: orden.vehiculo, asegurado: orden.cliente)

      expect { corregir(total_cerrado: "12000") }.to raise_error(ActiveRecord::RecordInvalid, /Confirmá que los revisaste/)
    end

    it "deja marcada la revisión confirmada en la auditoría" do
      orden.update!(franquicia: 1_000)

      corregir(total_cerrado: "12000", confirmar_revision: true)

      expect(orden.correcciones.sole.revision_confirmada).to be(true)
    end
  end
end
