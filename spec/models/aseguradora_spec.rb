require "rails_helper"

RSpec.describe Aseguradora, type: :model do
  it "es válida con los datos de la factory" do
    expect(build(:aseguradora)).to be_valid
  end

  it "exige nombre" do
    aseguradora = Aseguradora.new(nombre: "  ")

    expect(aseguradora).not_to be_valid
    expect(aseguradora.errors.attribute_names).to include(:nombre)
  end

  it "rechaza un nombre de más de 200 caracteres" do
    expect(build(:aseguradora, nombre: "a" * 201)).not_to be_valid
  end

  it "normaliza los espacios del nombre conservando las mayúsculas" do
    expect(create(:aseguradora, nombre: "  La   Segunda ").nombre).to eq("La Segunda")
  end

  it "rechaza un nombre repetido sin distinguir mayúsculas" do
    create(:aseguradora, nombre: "La Segunda")

    aseguradora = build(:aseguradora, nombre: " LA   segunda ")

    expect(aseguradora).not_to be_valid
    expect(aseguradora.errors.attribute_names).to include(:nombre)
  end

  it "impide en base de datos dos nombres iguales sin distinguir mayúsculas" do
    create(:aseguradora, nombre: "La Segunda")

    expect {
      build(:aseguradora, nombre: "LA SEGUNDA").save!(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "permite no cargar teléfono ni email" do
    expect(build(:aseguradora, telefono: nil, email: nil)).to be_valid
  end

  it "guarda teléfono y email vacíos como nulos" do
    aseguradora = create(:aseguradora, telefono: "  ", email: "  ")

    expect(aseguradora.telefono).to be_nil
    expect(aseguradora.email).to be_nil
  end

  it "normaliza teléfono y email" do
    aseguradora = create(:aseguradora, telefono: " (011) 4555-1234 ", email: " Siniestros@Seguro.TEST ")

    expect(aseguradora.telefono).to eq("01145551234")
    expect(aseguradora.email).to eq("siniestros@seguro.test")
  end

  it "rechaza un teléfono con letras" do
    expect(build(:aseguradora, telefono: "11-ABCD-1234")).not_to be_valid
  end

  it "rechaza un email inválido" do
    expect(build(:aseguradora, email: "siniestros")).not_to be_valid
  end

  it "queda activa al crearse" do
    expect(Aseguradora.create!(nombre: "Sancor")).to be_activa
  end

  it "filtra las activas" do
    activa = create(:aseguradora)
    create(:aseguradora, :desactivada)

    expect(Aseguradora.activas).to contain_exactly(activa)
  end
end
