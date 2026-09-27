require "rails_helper"

RSpec.describe TareaFrecuente, type: :model do
  it "es válida con los datos de la factory" do
    expect(build(:tarea_frecuente)).to be_valid
  end

  it "exige descripción y precio sugerido" do
    tarea_frecuente = TareaFrecuente.new

    expect(tarea_frecuente).not_to be_valid
    expect(tarea_frecuente.errors.attribute_names).to include(:descripcion, :precio_sugerido)
  end

  it "rechaza un precio sugerido menor o igual a cero" do
    expect(build(:tarea_frecuente, precio_sugerido: 0)).not_to be_valid
  end

  it "normaliza la descripción" do
    expect(create(:tarea_frecuente, descripcion: "  Cambio de aceite  ").descripcion).to eq("Cambio de aceite")
  end

  it "no permite dos tareas frecuentes con la misma descripción sin importar mayúsculas" do
    create(:tarea_frecuente, descripcion: "Cambio de aceite")

    duplicada = build(:tarea_frecuente, descripcion: "cambio de aceite")

    expect(duplicada).not_to be_valid
    expect(duplicada.errors[:descripcion]).to include("ya está en uso")
  end

  it "impide descripciones duplicadas a nivel de base de datos" do
    create(:tarea_frecuente, descripcion: "Cambio de aceite")
    duplicada = build(:tarea_frecuente, descripcion: "Cambio de aceite")

    expect { duplicada.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
