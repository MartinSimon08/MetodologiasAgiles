require "rails_helper"

RSpec.describe Adelanto, type: :model do
  it "es válido con importe positivo para una orden abierta" do
    orden = create(:orden)

    adelanto = build(:adelanto, orden: orden, importe: "2500.00")

    expect(adelanto).to be_valid
  end

  it "rechaza importes no positivos" do
    adelanto = build(:adelanto, importe: "0")

    expect(adelanto).not_to be_valid
    expect(adelanto.errors[:importe]).to include("debe ser mayor que 0")
  end

  it "solo puede asociarse a una orden abierta" do
    adelanto = build(:adelanto, orden: create(:orden, :cerrada), importe: "2500")

    expect(adelanto).not_to be_valid
    expect(adelanto.errors[:orden]).to include("debe estar abierta")
  end

  it "calcula el saldo restante de la orden" do
    orden = create(:orden)
    create(:tarea, orden: orden, precio: 3_000)
    create(:repuesto, orden: orden, precio_cliente: 2_500, costo_unitario: 2_000, margen: 25, registrado_por: create(:usuario))
    create(:adelanto, orden: orden, importe: "2_000.00")

    expect(orden.saldo).to eq(BigDecimal("3_500.00"))
  end
end
