require "rails_helper"

RSpec.describe Tarea, type: :model do
  it "es válida con los datos de la factory" do
    expect(build(:tarea)).to be_valid
  end

  it "exige descripción" do
    tarea = Tarea.new(orden: build(:orden))

    expect(tarea).not_to be_valid
    expect(tarea.errors.attribute_names).to include(:descripcion)
  end

  it "rechaza un estado desconocido" do
    expect(build(:tarea, estado: "cancelada")).not_to be_valid
  end

  it "nace pendiente" do
    expect(create(:tarea)).to be_pendiente
  end

  it "permite no cargar precio" do
    expect(build(:tarea, precio: nil)).to be_valid
  end

  it "rechaza un precio negativo" do
    expect(build(:tarea, precio: -1)).not_to be_valid
  end

  it "no puede crearse sobre una orden cerrada" do
    orden = create(:orden, :cerrada)

    tarea = build(:tarea, orden: orden)

    expect(tarea).not_to be_valid
    expect(tarea.errors[:orden]).to be_present
  end

  it "no puede crearse sobre una orden cancelada" do
    tarea = build(:tarea, orden: create(:orden, :cancelada))

    expect(tarea).not_to be_valid
    expect(tarea.errors[:orden]).to include("está cancelada")
  end
end
