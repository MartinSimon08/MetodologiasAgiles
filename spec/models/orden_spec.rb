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

  it "exige el motivo de ingreso" do
    orden = build(:orden, motivo: "  ")

    expect(orden).not_to be_valid
    expect(orden.errors[:motivo]).to include("no puede estar en blanco")
  end

  it "rechaza un motivo demasiado largo" do
    expect(build(:orden, motivo: "a" * (Orden::MOTIVO_MAXIMO + 1))).not_to be_valid
  end

  it "quita los espacios sobrantes del motivo" do
    expect(build(:orden, motivo: "  Ruido al frenar ").motivo).to eq("Ruido al frenar")
  end

  it "nace abierta" do
    expect(create(:orden)).to be_abierta
  end

  it "rechaza un estado desconocido" do
    expect(build(:orden, estado: "pausada")).not_to be_valid
  end

  it "rechaza una segunda orden abierta para el mismo vehículo" do
    abierta = create(:orden)
    orden = build(:orden, vehiculo: abierta.vehiculo)

    expect(orden).not_to be_valid
    expect(orden.errors[:vehiculo]).to include("ya tiene una orden abierta")
  end

  it "permite abrir otra orden si la anterior del vehículo está cerrada" do
    cerrada = create(:orden, :cerrada)

    expect(build(:orden, vehiculo: cerrada.vehiculo)).to be_valid
  end

  it "permite varias órdenes cerradas para el mismo vehículo" do
    cerrada = create(:orden, :cerrada)

    expect(build(:orden, :cerrada, vehiculo: cerrada.vehiculo)).to be_valid
  end

  it "permite modificar una orden abierta" do
    orden = create(:orden)

    expect(orden.update(motivo: "Cambio de aceite")).to be true
  end

  it "no permite cerrar una orden con repuestos pendientes de valorizar" do
    orden = create(:orden)
    mecanico = create(:usuario)
    RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Filtro de aceite", cantidad: 1)

    expect(orden.update(estado: :cerrada)).to be false
    expect(orden.errors[:base]).to include("No se puede cerrar la orden porque tiene repuestos pendientes de valorizar")
  end

  it "permite cerrar una orden sin repuestos pendientes de valorizar" do
    orden = create(:orden)
    admin = create(:usuario, :administrador)
    RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro de aceite", cantidad: 1, costo_unitario: "100")

    expect(orden.update(estado: :cerrada)).to be true
  end

  it "la base impide dos órdenes abiertas para el mismo vehículo aunque se saltee la validación" do
    abierta = create(:orden)
    orden = build(:orden, vehiculo: abierta.vehiculo)

    expect { orden.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "no permite eliminarla si tiene tareas" do
    orden = create(:orden)
    create(:tarea, orden: orden)

    expect(orden.destroy).to be false
    expect(orden.errors[:base]).to be_present
  end
end
