require "rails_helper"

RSpec.describe CasoAsignarTurno do
  let(:admin) { create(:usuario, :administrador) }
  let(:caso) { create(:caso) }
  let(:manana) { Date.current + 1.day }

  def asignar(fecha, a: caso)
    described_class.call(caso_id: a.id, fecha_turno: fecha&.to_s, registrado_por: admin)
  end

  before { ConfiguracionTaller.actual.update!(cupo_diario: 2) }

  it "asigna la fecha a un caso sin turno y registra la asignación" do
    asignar(manana)

    expect(caso.reload.fecha_turno).to eq(manana)
    expect(caso.cambios_turno.sole).to have_attributes(fecha_anterior: nil, fecha_nueva: manana, registrado_por: admin)
  end

  it "reprograma conservando la fecha anterior en el historial" do
    asignar(manana)
    asignar(manana + 2.days)

    expect(caso.reload.fecha_turno).to eq(manana + 2.days)
    expect(caso.cambios_turno.map { |cambio| [ cambio.fecha_anterior, cambio.fecha_nueva ] })
      .to eq([ [ nil, manana ], [ manana, manana + 2.days ] ])
  end

  it "permite asignar el turno para hoy" do
    asignar(Date.current)

    expect(caso.reload.fecha_turno).to eq(Date.current)
  end

  it "rechaza una fecha anterior a hoy" do
    expect { asignar(Date.current - 1.day) }.to raise_error(ActiveRecord::RecordInvalid, /no puede ser anterior a hoy/)
    expect(caso.reload.fecha_turno).to be_nil
    expect(CambioTurno.count).to eq(0)
  end

  it "rechaza reprogramar a la misma fecha" do
    asignar(manana)

    expect { asignar(manana) }.to raise_error(ActiveRecord::RecordInvalid, /misma fecha/)
    expect(CambioTurno.count).to eq(1)
  end

  it "exige una fecha válida" do
    expect { asignar(nil) }.to raise_error(ActiveRecord::RecordInvalid, /Turno no puede estar en blanco/)
    expect { described_class.call(caso_id: caso.id, fecha_turno: "31/02", registrado_por: admin) }
      .to raise_error(ActiveRecord::RecordInvalid, /Turno no es válido/)
  end

  it "no permite pasar el cupo de ingresos del día" do
    create_list(:caso, 2, fecha_turno: manana)

    expect { asignar(manana) }.to raise_error(ActiveRecord::RecordInvalid, /ya hay 2 ingresos con cupo de 2/)
    expect(caso.reload.fecha_turno).to be_nil
  end

  it "no cuenta para el cupo los casos con la orden cerrada o cancelada" do
    otro = create(:caso, fecha_turno: Date.current)
    CasoIngresar.call(caso_id: otro.id)
    otro.reload.orden.update_columns(estado: "cancelada", cancelada_en: Time.current)
    create(:caso, fecha_turno: Date.current)

    asignar(Date.current)

    expect(caso.reload.fecha_turno).to eq(Date.current)
  end

  it "usa el cupo vigente al momento de asignar" do
    create(:caso, fecha_turno: manana)
    ConfiguracionTaller.actual.update!(cupo_diario: 1)

    expect { asignar(manana) }.to raise_error(ActiveRecord::RecordInvalid, /cupo de 1/)
  end

  it "no reprograma un caso que ya ingresó" do
    asignar(Date.current)
    CasoIngresar.call(caso_id: caso.id)

    expect { asignar(manana) }.to raise_error(ActiveRecord::RecordInvalid, /ya ingresó/)
    expect(caso.reload.fecha_turno).to eq(Date.current)
    expect(CambioTurno.count).to eq(1)
  end
end
