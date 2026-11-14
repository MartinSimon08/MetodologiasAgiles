require "rails_helper"

RSpec.describe ConsultaCasosAseguradora do
  let(:admin) { create(:usuario, :administrador) }
  let(:aseguradora) { create(:aseguradora, nombre: "Sancor") }

  def consultar(**filtros)
    described_class.call(**{ aseguradora_id: aseguradora.id, desde: "2026-04-01", hasta: "2026-04-30" }.merge(filtros))
  end

  def caso_el(momento, compania: aseguradora)
    travel_to(momento) { create(:caso, aseguradora: compania) }
  end

  def vincular(caso, precio:, adelantos: [], terminar: false)
    orden = create(:orden, cliente: caso.asegurado, vehiculo: caso.vehiculo)
    atributos = { orden: orden, precio: precio }
    atributos[:estado] = :terminada if terminar
    atributos[:mecanico] = admin if terminar
    atributos[:tomada_en] = 1.hour.ago if terminar
    atributos[:terminada_en] = Time.current if terminar
    create(:tarea, **atributos)
    adelantos.each { |importe| create(:adelanto, orden: orden, importe: importe, registrado_por: admin) }
    caso.update!(orden: orden)
    orden
  end

  it "lista los casos de la aseguradora en el período y suma los totales" do
    con_adelantos = caso_el(Time.zone.local(2026, 4, 2, 9))
    vincular(con_adelantos, precio: "1000", adelantos: [ "200", "50" ])
    sin_cobro = caso_el(Time.zone.local(2026, 4, 15, 12))
    vincular(sin_cobro, precio: "400")
    sin_orden = caso_el(Time.zone.local(2026, 4, 20, 8))
    ajena = caso_el(Time.zone.local(2026, 4, 10, 12), compania: create(:aseguradora))
    vincular(ajena, precio: "900", adelantos: [ "100" ])
    caso_el(Time.zone.local(2026, 3, 31, 23, 59, 59))

    consulta = consultar

    expect(consulta).to be_valid
    expect(consulta.filas.map(&:caso)).to eq([ con_adelantos, sin_cobro, sin_orden ])
    expect(consulta.filas.map { |fila| [ fila.total_autorizado, fila.franquicia_cobrada, fila.saldo_pendiente ] })
      .to eq([ %w[1000.0 0.0 1000.0], %w[400.0 0.0 400.0], %w[0.0 0.0 0.0] ])
    expect(consulta.totales).to have_attributes(
      total_autorizado: "1400.0", franquicia_cobrada: "0.0", saldo_pendiente: "1400.0"
    )
  end

  it "incluye los casos abiertos en los extremos del día" do
    inicio = caso_el(Time.zone.local(2026, 4, 1, 0, 0, 0))
    fin = caso_el(Time.zone.local(2026, 4, 30, 23, 59, 59))
    caso_el(Time.zone.local(2026, 5, 1, 0, 0, 0))

    expect(consultar.filas.map(&:caso)).to eq([ inicio, fin ])
  end

  it "usa el total cerrado y la franquicia registrada, sin descontar los adelantos" do
    caso = caso_el(Time.zone.local(2026, 4, 10, 12))
    orden = vincular(caso, precio: "800", adelantos: [ "100" ], terminar: true)
    OrdenCerrar.call(orden: orden, cerrada_por: admin, franquicia: "250")
    orden.update_column(:total_cerrado, BigDecimal("650"))

    fila = consultar.filas.sole

    expect(fila.total_autorizado).to eq("650.0")
    expect(fila.franquicia_cobrada).to eq("250.0")
    expect(fila.saldo_pendiente).to eq("400.0")
  end

  it "en una orden abierta deja la franquicia en cero y el saldo pendiente igual al total" do
    caso = caso_el(Time.zone.local(2026, 4, 10, 12))
    orden = create(:orden, cliente: caso.asegurado, vehiculo: caso.vehiculo)
    repuesto = RepuestoAgregar.call(
      orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 2,
      costo_unitario: "100", margen: "20"
    )
    create(:adelanto, orden: orden, importe: "40", registrado_por: admin)
    RepuestoRegistrarAjuste.call(
      repuesto: repuesto, registrado_por: admin, tipo: "devolucion", cantidad: 1,
      costo_unitario: "100", motivo: "Sobra"
    )
    caso.update!(orden: orden)

    fila = consultar.filas.sole

    expect(fila.total_autorizado).to eq("120.0")
    expect(fila.franquicia_cobrada).to eq("0.0")
    expect(fila.saldo_pendiente).to eq("120.0")
  end

  it "calcula una sola vez el total de una orden abierta" do
    caso = caso_el(Time.zone.local(2026, 4, 8, 12))
    vincular(caso, precio: "1000", adelantos: [ "250" ])
    consultas = []
    consulta = nil
    ActiveSupport::Notifications.subscribed(
      ->(_name, _start, _finish, _id, payload) { consultas << payload[:sql] },
      "sql.active_record"
    ) { consulta = consultar }

    expect(consultas.count { |sql| sql.include?("SUM(") }).to eq(3)
    expect(consulta.filas.sole).to have_attributes(
      total_autorizado: "1000.0", franquicia_cobrada: "0.0", saldo_pendiente: "1000.0"
    )
  end

  it "consulta una aseguradora desactivada" do
    caso = caso_el(Time.zone.local(2026, 4, 10, 12))
    aseguradora.update!(activa: false)

    expect(consultar.filas.map(&:caso)).to eq([ caso ])
  end

  it "devuelve totales en cero cuando la aseguradora no tiene casos en el período" do
    consulta = consultar

    expect(consulta).to be_valid
    expect(consulta.filas).to be_empty
    expect(consulta.totales).to have_attributes(
      total_autorizado: "0.0", franquicia_cobrada: "0.0", saldo_pendiente: "0.0"
    )
  end

  it "rechaza una aseguradora en blanco o inexistente y un período inválido" do
    expect(consultar(aseguradora_id: nil, desde: nil, hasta: "2026-04-30").errors).to eq(
      aseguradora: [ "no puede estar en blanco" ], desde: [ "no puede estar en blanco" ]
    )
    expect(consultar(aseguradora_id: "", desde: "2026-04-01", hasta: "").errors).to eq(
      aseguradora: [ "no puede estar en blanco" ], hasta: [ "no puede estar en blanco" ]
    )
    expect(consultar(aseguradora_id: "abc", desde: "15/04/2026", hasta: "2026-04-30").errors).to eq(
      aseguradora: [ "no es válida" ], desde: [ "no es una fecha válida" ]
    )
    expect(consultar(aseguradora_id: 0, desde: "2026-04-30", hasta: "2026-04-01").errors).to eq(
      aseguradora: [ "no es válida" ], hasta: [ "debe ser posterior o igual a la fecha desde" ]
    )
    expect(consultar(aseguradora_id: aseguradora.id + 1)).to be_invalid
    expect(consultar(desde: "2026-04-01", hasta: "2026-04-01")).to be_valid
  end
end
