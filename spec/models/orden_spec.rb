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

    expect(orden.update(estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin, total_cerrado: 100)).to be true
  end

  it "exige quién cerró, cuándo y el total en una orden cerrada" do
    orden = build(:orden, :cerrada, cerrada_en: nil, cerrada_por: nil, total_cerrado: nil)

    expect(orden).not_to be_valid
    expect(orden.errors.attribute_names).to include(:cerrada_en, :cerrada_por, :total_cerrado)
  end

  it "rechaza datos de cierre en una orden que no está cerrada" do
    expect(build(:orden, cerrada_en: Time.current)).not_to be_valid
    expect(build(:orden, total_cerrado: 100)).not_to be_valid
  end

  it "la base rechaza una orden cerrada sin datos de cierre aunque se saltee la validación" do
    orden = create(:orden)

    expect { orden.update_column(:estado, "cerrada") }.to raise_error(ActiveRecord::StatementInvalid, /ordenes_cierre_consistente/)
  end

  describe "#total_a_cobrar" do
    let(:orden) { create(:orden) }
    let(:admin) { create(:usuario, :administrador) }

    it "suma la mano de obra de las tareas terminadas y el precio de los repuestos" do
      create(:tarea, :terminada, orden: orden, precio: 15_000)
      create(:tarea, :terminada, orden: orden, precio: 5_000)
      create(:tarea, :terminada, orden: orden, precio: nil)
      create(:tarea, :en_curso, orden: orden, precio: 7_000)
      create(:tarea, orden: orden, precio: 3_000)
      RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 2,
                           costo_unitario: "1000", margen: 50)
      RepuestoAvisar.call(orden: orden, registrado_por: create(:usuario), descripcion: "Correa", cantidad: 1)

      expect(orden.mano_de_obra).to eq(20_000)
      expect(orden.total_repuestos).to eq(3_000)
      expect(orden.total_a_cobrar).to eq(23_000)
    end
  end

  describe "#total" do
    it "suma la mano de obra de las tareas no descartadas y el precio de los repuestos valorizados" do
      orden = create(:orden)
      create(:tarea, :terminada, orden: orden, precio: 15_000)
      create(:tarea, orden: orden, precio: 3_000)
      create(:tarea, orden: orden, precio: 9_000, estado: :cancelada)
      RepuestoAgregar.call(orden: orden, registrado_por: create(:usuario, :administrador), descripcion: "Filtro",
                           cantidad: 1, costo_unitario: "1000", margen: 50)
      RepuestoAvisar.call(orden: orden, registrado_por: create(:usuario), descripcion: "Correa", cantidad: 1)

      expect(orden.mano_de_obra_cargada).to eq(18_000)
      expect(orden.total).to eq(19_500)
    end
  end

  it "devuelve el total congelado de una orden cerrada" do
    orden = create(:orden, :cerrada, total_cerrado: 12_345)
    create(:tarea, :terminada, orden: create(:orden, vehiculo: orden.vehiculo), precio: 1)

    expect(orden.total).to eq(12_345)
  end

  it "la base impide dos órdenes abiertas para el mismo vehículo aunque se saltee la validación" do
    abierta = create(:orden)
    orden = build(:orden, vehiculo: abierta.vehiculo)

    expect { orden.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "exige la fecha de cancelación en una orden cancelada" do
    orden = build(:orden, :cancelada, cancelada_en: nil)

    expect(orden).not_to be_valid
    expect(orden.errors[:cancelada_en]).to include("no puede estar en blanco")
  end

  it "rechaza una fecha de cancelación en una orden que no está cancelada" do
    expect(build(:orden, cancelada_en: Time.current)).not_to be_valid
    expect(build(:orden, :cerrada, cancelada_en: Time.current)).not_to be_valid
  end

  it "la base rechaza una orden cancelada sin fecha aunque se saltee la validación" do
    orden = create(:orden)

    expect { orden.update_columns(estado: "cancelada") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "permite abrir otra orden si la anterior del vehículo está cancelada" do
    cancelada = create(:orden, :cancelada)

    expect(build(:orden, vehiculo: cancelada.vehiculo)).to be_valid
  end

  it "no permite eliminarla si tiene tareas" do
    orden = create(:orden)
    create(:tarea, orden: orden)

    expect(orden.destroy).to be false
    expect(orden.errors[:base]).to be_present
  end

  it "no suma al total un repuesto quitado" do
    orden = create(:orden)
    admin = create(:usuario, :administrador)
    vigente = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Bujía",
                                   cantidad: 1, costo_unitario: "50", margen: "20")
    quitado = RepuestoAgregar.call(orden: orden, registrado_por: admin, descripcion: "Filtro",
                                   cantidad: 2, costo_unitario: "100.50", margen: "20")

    RepuestoQuitar.call(repuesto: quitado, quitado_por: admin)

    expect(orden.reload.total).to eq(vigente.precio_cliente)
  end

  it "permite cerrar la orden si el repuesto pendiente ya fue quitado" do
    orden = create(:orden)
    admin = create(:usuario, :administrador)
    pendiente = RepuestoAvisar.call(orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 1)

    RepuestoQuitar.call(repuesto: pendiente, quitado_por: admin)

    expect(orden.update(estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin,
                        total_cerrado: orden.total_a_cobrar)).to be true
  end
end
