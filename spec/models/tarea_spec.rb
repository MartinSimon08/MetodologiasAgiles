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

  it "no puede crearse sobre una orden cerrada" do
    orden = create(:orden, :cerrada)

    tarea = build(:tarea, orden: orden)

    expect(tarea).not_to be_valid
    expect(tarea.errors[:orden]).to be_present
  end
end
