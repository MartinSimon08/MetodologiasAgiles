require "rails_helper"

RSpec.describe ReporteTareasPorMecanico do
  def consultar(**filtros)
    described_class.call(**filtros)
  end

  it "muestra en 0 a un mecánico activo que no tomó ni completó nada en el período" do
    mecanico = create(:usuario, nombre: "Ana")

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta).to be_valid
    expect(consulta.filas.map { |fila| [ fila.mecanico, fila.tomadas, fila.completadas ] })
      .to contain_exactly([ mecanico, 0, 0 ])
  end

  it "cuenta las tareas tomadas y completadas por mecánico dentro del período" do
    ana = create(:usuario, nombre: "Ana")
    beto = create(:usuario, nombre: "Beto")

    travel_to(Time.zone.local(2026, 4, 10, 12)) do
      create(:tarea, :en_curso, mecanico: ana)
      create(:tarea, :terminada, mecanico: ana)
      create(:tarea, :terminada, mecanico: beto)
    end
    travel_to(Time.zone.local(2026, 4, 15, 12)) { create(:tarea, :en_curso, mecanico: beto) }

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    fila_ana = consulta.filas.find { |fila| fila.mecanico == ana }
    fila_beto = consulta.filas.find { |fila| fila.mecanico == beto }
    expect([ fila_ana.tomadas, fila_ana.completadas ]).to eq([ 2, 1 ])
    expect([ fila_beto.tomadas, fila_beto.completadas ]).to eq([ 2, 1 ])
  end

  it "filtra por período inclusive según cuándo se tomó o se terminó, no cuándo se creó" do
    mecanico = create(:usuario)
    tarea = travel_to(Time.zone.local(2026, 3, 1, 12)) { create(:tarea) }

    travel_to(Time.zone.local(2026, 4, 1, 0)) { TareaTomar.call(tarea: tarea, mecanico: mecanico) }
    travel_to(Time.zone.local(2026, 4, 30, 23, 59, 59)) { TareaCompletar.call(tarea: tarea) }

    dentro = consultar(desde: "2026-04-01", hasta: "2026-04-30")
    fuera = consultar(desde: "2026-05-01", hasta: "2026-05-31")

    fila_dentro = dentro.filas.find { |fila| fila.mecanico == mecanico }
    fila_fuera = fuera.filas.find { |fila| fila.mecanico == mecanico }
    expect([ fila_dentro.tomadas, fila_dentro.completadas ]).to eq([ 1, 1 ])
    expect([ fila_fuera.tomadas, fila_fuera.completadas ]).to eq([ 0, 0 ])
  end

  it "solo refleja la toma vigente de una tarea: una toma anterior que se liberó no queda registrada" do
    primero = create(:usuario)
    segundo = create(:usuario)
    tarea = create(:tarea)

    travel_to(Time.zone.local(2026, 4, 5, 10)) { TareaTomar.call(tarea: tarea, mecanico: primero) }
    travel_to(Time.zone.local(2026, 4, 6, 10)) { TareaLiberar.call(tarea: tarea) }
    travel_to(Time.zone.local(2026, 4, 7, 10)) { TareaTomar.call(tarea: tarea.reload, mecanico: segundo) }

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    fila_primero = consulta.filas.find { |fila| fila.mecanico == primero }
    fila_segundo = consulta.filas.find { |fila| fila.mecanico == segundo }
    expect([ fila_primero.tomadas, fila_primero.completadas ]).to eq([ 0, 0 ])
    expect([ fila_segundo.tomadas, fila_segundo.completadas ]).to eq([ 1, 0 ])
  end

  it "no incluye administradores en el reporte" do
    create(:usuario, :administrador)
    mecanico = create(:usuario)

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.filas.map(&:mecanico)).to eq([ mecanico ])
  end

  it "rechaza fechas inválidas, un período invertido o fechas en blanco" do
    expect(consultar(desde: nil, hasta: "2026-04-30").errors).to eq(desde: [ "no puede estar en blanco" ])
    expect(consultar(desde: "2026-04-01", hasta: "").errors).to eq(hasta: [ "no puede estar en blanco" ])
    expect(consultar(desde: "15/04/2026", hasta: "2026-04-30").errors).to eq(desde: [ "no es una fecha válida" ])
    expect(consultar(desde: "2026-04-30", hasta: "2026-04-01").errors).to eq(
      hasta: [ "debe ser posterior o igual a la fecha desde" ]
    )
    expect(consultar(desde: "2026-04-01", hasta: "2026-04-01")).to be_valid
  end
end
