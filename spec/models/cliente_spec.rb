require "rails_helper"

RSpec.describe Cliente, type: :model do
  it "es válido con los datos de la factory" do
    expect(build(:cliente)).to be_valid
  end

  it "exige nombre y teléfono" do
    cliente = Cliente.new

    expect(cliente).not_to be_valid
    expect(cliente.errors.attribute_names).to include(:nombre, :telefono)
  end

  it "permite no cargar email" do
    expect(build(:cliente, email: nil)).to be_valid
  end

  it "guarda un email vacío como nulo" do
    expect(create(:cliente, email: "  ").email).to be_nil
  end

  it "normaliza el email" do
    expect(create(:cliente, email: "  Ana@Correo.TEST ").email).to eq("ana@correo.test")
  end

  it "rechaza un email inválido" do
    expect(build(:cliente, email: "ana")).not_to be_valid
  end

  it "normaliza el teléfono quitando espacios, guiones y paréntesis" do
    expect(create(:cliente, telefono: " (011) 4555-1234 ").telefono).to eq("01145551234")
  end

  it "conserva el prefijo internacional" do
    expect(create(:cliente, telefono: "+54 9 11 5555-1234").telefono).to eq("+5491155551234")
  end

  it "rechaza un teléfono con letras" do
    cliente = build(:cliente, telefono: "11-ABCD-1234")

    expect(cliente).not_to be_valid
    expect(cliente.errors[:telefono]).to be_present
  end

  it "no permite dos clientes con el mismo teléfono aunque tengan otro formato" do
    create(:cliente, telefono: "1145551234")

    duplicado = build(:cliente, telefono: "11 4555-1234")

    expect(duplicado).not_to be_valid
    expect(duplicado.errors[:telefono]).to include("ya está en uso")
  end

  it "impide teléfonos duplicados a nivel de base de datos" do
    create(:cliente, telefono: "1145551234")
    duplicado = build(:cliente, telefono: "1145551234")

    expect { duplicado.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
