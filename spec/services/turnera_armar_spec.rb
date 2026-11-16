require "rails_helper"

RSpec.describe TurneraArmar do
  let(:lunes) { Date.new(2026, 11, 9) }
  let(:miercoles) { Date.new(2026, 11, 11) }

  def caso_ingresado(fecha, tareas: [])
    caso = create(:caso, fecha_turno: fecha)
    orden = create(:orden, vehiculo: caso.vehiculo, cliente: caso.asegurado)
    tareas.each { |trait| create(:tarea, *Array(trait), orden: orden) }
    caso.update!(orden: orden)
    caso
  end

  it "arma la semana de lunes a domingo que contiene la fecha" do
    resultado = described_class.call(fecha: miercoles.iso8601)

    expect(resultado).to be_valid
    expect(resultado.desde).to eq(lunes)
    expect(resultado.hasta).to eq(Date.new(2026, 11, 15))
    expect(resultado.dias.map(&:fecha)).to eq((lunes..Date.new(2026, 11, 15)).to_a)
  end

  it "usa la semana actual cuando no recibe fecha" do
    travel_to(Time.zone.local(2026, 11, 11, 10)) do
      expect(described_class.call.desde).to eq(lunes)
    end
  end

  it "agrupa los casos con turno por día y deja afuera los que no tienen turno o caen fuera de la semana" do
    del_lunes = create(:caso, fecha_turno: lunes)
    del_miercoles = create(:caso, fecha_turno: miercoles)
    create(:caso, fecha_turno: nil)
    create(:caso, fecha_turno: lunes - 1.day)

    dias = described_class.call(fecha: lunes.iso8601).dias.index_by(&:fecha)

    expect(dias[lunes].turnos.map(&:caso)).to eq([ del_lunes ])
    expect(dias[miercoles].turnos.map(&:caso)).to eq([ del_miercoles ])
    expect(dias[lunes + 1.day].turnos).to be_empty
  end

  it "distingue turno asignado, ingresado y listo para retirar" do
    asignado = create(:caso, fecha_turno: lunes)
    sin_tareas = caso_ingresado(lunes)
    con_pendientes = caso_ingresado(lunes, tareas: [ :terminada, :en_curso ])
    listo = caso_ingresado(lunes, tareas: [ :terminada, :terminada ])

    turnos = described_class.call(fecha: lunes.iso8601).dias.first.turnos.to_h { |turno| [ turno.caso, turno.estado ] }

    expect(turnos).to eq(
      asignado => "turno_asignado",
      sin_tareas => "ingresado",
      con_pendientes => "ingresado",
      listo => "listo_para_retirar"
    )
  end

  it "no muestra los casos cuya orden ya fue cerrada o cancelada" do
    %i[cerrada cancelada].each do |trait|
      caso = create(:caso, fecha_turno: lunes)
      caso.update!(orden: create(:orden, trait, vehiculo: caso.vehiculo, cliente: caso.asegurado))
    end

    expect(described_class.call(fecha: lunes.iso8601).dias.first.turnos).to be_empty
  end

  it "cuenta los ingresos de cada día contra el cupo diario y marca los que lo superan" do
    ConfiguracionTaller.actual.update!(cupo_diario: 2)
    create_list(:caso, 2, fecha_turno: lunes)
    create_list(:caso, 3, fecha_turno: miercoles)

    resultado = described_class.call(fecha: lunes.iso8601)
    dias = resultado.dias.index_by(&:fecha)

    expect(resultado.cupo_diario).to eq(2)
    expect(dias[lunes]).to have_attributes(ingresos: 2, supera_cupo?: false)
    expect(dias[miercoles]).to have_attributes(ingresos: 3, supera_cupo?: true)
    expect(dias[lunes + 1.day]).to have_attributes(ingresos: 0, supera_cupo?: false)
  end

  it "rechaza una fecha inválida" do
    resultado = described_class.call(fecha: "2026-13-40")

    expect(resultado).to be_invalid
    expect(resultado.errors).to eq(fecha: [ "no es una fecha válida" ])
  end
end
