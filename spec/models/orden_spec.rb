require "rails_helper"

RSpec.describe Orden, type: :model do
  it "es válida con los datos de la factory" do
    expect(build(:orden)).to be_valid
  end

  it "exige cliente y vehículo" do
    orden = Orden.new

    expect(orden).not_to be_valid
    expect(orden.errors.attribute_names).to include(:cliente, :vehiculo)
  end

  it "nace abierta" do
    expect(create(:orden)).to be_abierta
  end

  it "rechaza un estado desconocido" do
    expect(build(:orden, estado: "pausada")).not_to be_valid
  end

  it "no permite eliminarla si tiene tareas" do
    orden = create(:orden)
    create(:tarea, orden: orden)

    expect(orden.destroy).to be false
    expect(orden.errors[:base]).to be_present
  end
end
