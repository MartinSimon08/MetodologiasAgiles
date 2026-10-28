require "rails_helper"

RSpec.describe Caso, type: :model do
  it "es válido con los datos de la factory" do
    expect(build(:caso)).to be_valid
  end

  it "nace sin turno y sin orden" do
    caso = create(:caso)

    expect(caso).to have_attributes(fecha_turno: nil, orden: nil)
  end

  %i[aseguradora asegurado vehiculo].each do |asociacion|
    it "exige #{asociacion}" do
      caso = build(:caso)
      caso.public_send("#{asociacion}=", nil)

      expect(caso).not_to be_valid
      expect(caso.errors.attribute_names).to include(asociacion)
    end
  end

  it "exige número de siniestro" do
    caso = build(:caso, numero_siniestro: "   ")

    expect(caso).not_to be_valid
    expect(caso.errors.attribute_names).to include(:numero_siniestro)
  end

  it "rechaza un número de siniestro de más de 50 caracteres" do
    expect(build(:caso, numero_siniestro: "1" * 51)).not_to be_valid
  end

  it "normaliza espacios y mayúsculas del número de siniestro" do
    expect(create(:caso, numero_siniestro: "  sin  123-a ").numero_siniestro).to eq("SIN 123-A")
  end

  it "rechaza el mismo número de siniestro para la misma aseguradora" do
    existente = create(:caso, numero_siniestro: "SIN-1")

    caso = build(:caso, aseguradora: existente.aseguradora, numero_siniestro: " sin-1 ")

    expect(caso).not_to be_valid
    expect(caso.errors.details[:numero_siniestro]).to include(a_hash_including(error: :taken))
  end

  it "permite el mismo número de siniestro en otra aseguradora" do
    create(:caso, numero_siniestro: "SIN-1")

    expect(build(:caso, numero_siniestro: "SIN-1")).to be_valid
  end

  it "impide en base de datos duplicar el número de siniestro de una aseguradora" do
    existente = create(:caso, numero_siniestro: "SIN-1")

    expect {
      build(:caso, aseguradora: existente.aseguradora, numero_siniestro: "SIN-1").save!(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rechaza un vehículo que no es del asegurado" do
    caso = build(:caso, vehiculo: create(:vehiculo))

    expect(caso).not_to be_valid
    expect(caso.errors.details[:vehiculo]).to include(error: :no_es_del_asegurado)
  end

  it "rechaza abrir un caso con una aseguradora desactivada" do
    caso = build(:caso, aseguradora: create(:aseguradora, :desactivada))

    expect(caso).not_to be_valid
    expect(caso.errors.details[:aseguradora]).to include(error: :desactivada)
  end

  it "conserva el caso aunque su aseguradora se desactive después" do
    caso = create(:caso)
    caso.aseguradora.update!(activa: false)

    expect(caso.reload).to be_valid
  end

  it "guarda la descripción opcional sin espacios sobrantes" do
    expect(create(:caso, descripcion: "  Choque trasero  ").descripcion).to eq("Choque trasero")
    expect(create(:caso, descripcion: "   ").descripcion).to be_nil
  end

  it "rechaza una descripción de más de 1000 caracteres" do
    expect(build(:caso, descripcion: "a" * 1001)).not_to be_valid
  end
end
