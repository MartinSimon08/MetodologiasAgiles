require "rails_helper"

RSpec.describe Vehiculo, type: :model do
  it "es válido con los datos de la factory" do
    expect(build(:vehiculo)).to be_valid
  end

  it "exige patente y dueño" do
    vehiculo = Vehiculo.new

    expect(vehiculo).not_to be_valid
    expect(vehiculo.errors.attribute_names).to include(:patente, :cliente)
  end

  it "permite registrar solo la patente" do
    vehiculo = build(:vehiculo, marca: nil, modelo: nil, anio: nil, kilometraje: nil)

    expect(vehiculo).to be_valid
  end

  it "normaliza la patente a mayúsculas sin espacios ni guiones" do
    expect(create(:vehiculo, patente: " ab 123-cd ").patente).to eq("AB123CD")
  end

  it "guarda marca y modelo vacíos como nulos" do
    vehiculo = create(:vehiculo, marca: "  ", modelo: "")

    expect(vehiculo.marca).to be_nil
    expect(vehiculo.modelo).to be_nil
  end

  it "rechaza una patente con caracteres inválidos" do
    vehiculo = build(:vehiculo, patente: "AB#123")

    expect(vehiculo).not_to be_valid
    expect(vehiculo.errors[:patente]).to be_present
  end

  it "no permite dos vehículos con la misma patente aunque tengan otro formato" do
    create(:vehiculo, patente: "AB123CD")

    duplicado = build(:vehiculo, patente: "ab 123 cd")

    expect(duplicado).not_to be_valid
    expect(duplicado.errors[:patente]).to include("ya está en uso")
  end

  it "impide patentes duplicadas a nivel de base de datos" do
    create(:vehiculo, patente: "AB123CD")
    duplicado = build(:vehiculo, patente: "AB123CD")

    expect { duplicado.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rechaza un año anterior a 1900 o posterior al próximo" do
    expect(build(:vehiculo, anio: 1899)).not_to be_valid
    expect(build(:vehiculo, anio: Date.current.year + 2)).not_to be_valid
    expect(build(:vehiculo, anio: Date.current.year + 1)).to be_valid
  end

  it "rechaza un kilometraje negativo o con decimales" do
    expect(build(:vehiculo, kilometraje: -1)).not_to be_valid
    expect(build(:vehiculo, kilometraje: "10.5")).not_to be_valid
  end

  it "impide eliminar un cliente con vehículos" do
    vehiculo = create(:vehiculo)

    expect(vehiculo.cliente.destroy).to be(false)
    expect(vehiculo.cliente.errors[:base]).to be_present
  end
end
