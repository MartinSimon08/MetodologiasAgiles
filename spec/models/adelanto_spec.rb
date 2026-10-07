require "rails_helper"

RSpec.describe Adelanto, type: :model do
  it "es válido con importe positivo para una orden abierta" do
    orden = create(:orden)
    create(:tarea, orden: orden, precio: 3_000)

    adelanto = build(:adelanto, orden: orden, importe: "2500.00")

    expect(adelanto).to be_valid
  end

  it "acepta un importe igual al monto final" do
    orden = create(:orden)
    create(:tarea, orden: orden, precio: 1_000)

    adelanto = build(:adelanto, orden: orden, importe: "1000.00")

    expect(adelanto).to be_valid
  end

  it "rechaza un importe mayor al monto final" do
    orden = create(:orden)
    create(:tarea, orden: orden, precio: 1_000)

    adelanto = build(:adelanto, orden: orden, importe: "1000.01")

    expect(adelanto).not_to be_valid
    expect(adelanto.errors[:importe]).to include("no puede ser mayor al monto final de la orden")
  end

  it "rechaza un importe que, sumado a los adelantos, supera el monto final" do
    orden = create(:orden)
    create(:tarea, orden: orden, precio: 1_000)
    create(:adelanto, orden: orden, importe: "600.00")

    adelanto = build(:adelanto, orden: orden, importe: "500.00")

    expect(adelanto).not_to be_valid
    expect(adelanto.errors[:importe]).to include("no puede ser mayor al monto final de la orden")
  end

  it "acepta un importe igual al saldo restante" do
    orden = create(:orden)
    create(:tarea, orden: orden, precio: 1_000)
    create(:adelanto, orden: orden, importe: "600.00")

    adelanto = build(:adelanto, orden: orden, importe: "400.00")

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
    Repuesto.create!(
      orden: orden,
      descripcion: "Filtro",
      cantidad: 1,
      costo_unitario: 2_000,
      margen: 25,
      precio_cliente: 2_500,
      registrado_por: create(:usuario)
    )
    create(:adelanto, orden: orden, importe: "2_000.00")

    expect(orden.saldo).to eq(BigDecimal("3_500.00"))
  end
end
