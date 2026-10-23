require "rails_helper"

RSpec.describe TareaNota do
  it "es válida con los datos de la factory" do
    expect(build(:tarea_nota)).to be_valid
  end

  it "exige contenido" do
    nota = build(:tarea_nota, contenido: "")

    expect(nota).not_to be_valid
    expect(nota.errors[:contenido]).to be_present
  end

  it "rechaza un contenido más largo que el máximo permitido" do
    nota = build(:tarea_nota, contenido: "a" * (TareaNota::CONTENIDO_MAXIMO + 1))

    expect(nota).not_to be_valid
    expect(nota.errors[:contenido]).to be_present
  end

  it "normaliza el contenido sacando espacios de los bordes" do
    nota = create(:tarea_nota, contenido: "  Falta una junta  ")

    expect(nota.contenido).to eq("Falta una junta")
  end
end
