require "rails_helper"

RSpec.describe ReporteIngresos do
  let(:admin) { create(:usuario, :administrador) }

  def consultar(**filtros)
    described_class.call(**filtros)
  end

  def orden_con_monto(precio: 10_000)
    orden = create(:orden)
    create(:tarea, orden: orden, precio: precio)
    orden
  end

  def con_caso(orden)
    create(:caso, orden: orden, asegurado: orden.cliente, vehiculo: orden.vehiculo)
    orden
  end

  def adelantar(orden, importe, momento)
    travel_to(momento) { create(:adelanto, orden: orden, importe: importe, registrado_por: admin) }
  end

  def cerrar(orden, momento, franquicia: nil)
    travel_to(momento) do
      orden.update!(
        estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin,
        total_cerrado: orden.total, franquicia: franquicia
      )
    end
  end

  it "toma la franquicia de la orden cerrada y los adelantos solo de clientes directos" do
    asegurada = con_caso(orden_con_monto)
    adelantar(asegurada, "1000.00", Time.zone.local(2026, 3, 20, 12))
    adelantar(asegurada, "3000.00", Time.zone.local(2026, 4, 10, 12))
    cerrar(asegurada, Time.zone.local(2026, 4, 15, 18), franquicia: 4_000)

    directa = orden_con_monto(precio: 5_000)
    adelantar(directa, "2000.00", Time.zone.local(2026, 4, 12, 9))
    cerrar(directa, Time.zone.local(2026, 4, 20, 11))

    abierta = con_caso(orden_con_monto(precio: 8_000))
    adelantar(abierta, "500.00", Time.zone.local(2026, 4, 8, 15))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta).to be_valid
    expect(consulta.franquicia_cobrada).to eq("4000.0")
    expect(consulta.saldo_facturado_aseguradoras).to eq("0.0")
    expect(consulta.saldo_pendiente_aseguradoras).to eq("6000.0")
    expect(consulta.ingresos_clientes_directos).to eq("2000.0")
    expect(consulta.total_ingresos).to eq("6000.0")
  end

  it "sin franquicia registrada deja el total del caso como saldo pendiente y no lo suma al ingreso" do
    orden = con_caso(orden_con_monto)
    adelantar(orden, "4000.00", Time.zone.local(2026, 3, 15, 12))
    cerrar(orden, Time.zone.local(2026, 4, 10, 12))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.franquicia_cobrada).to eq("0.0")
    expect(consulta.saldo_facturado_aseguradoras).to eq("0.0")
    expect(consulta.saldo_pendiente_aseguradoras).to eq("10000.0")
    expect(consulta.ingresos_clientes_directos).to eq("0.0")
    expect(consulta.total_ingresos).to eq("0.0")
  end

  it "cuenta la franquicia al cerrar el caso y el adelanto directo al registrarlo" do
    asegurada = con_caso(orden_con_monto)
    adelantar(asegurada, "2500.00", Time.zone.local(2026, 4, 30, 23, 59, 59))
    cerrar(asegurada, Time.zone.local(2026, 5, 2, 10), franquicia: 2_500)

    directa = orden_con_monto(precio: 4_000)
    adelantar(directa, "800.00", Time.zone.local(2026, 4, 30, 23, 59, 59))
    cerrar(directa, Time.zone.local(2026, 5, 2, 10))

    abril = consultar(desde: "2026-04-01", hasta: "2026-04-30")
    mayo = consultar(desde: "2026-05-01", hasta: "2026-05-31")

    expect(abril.franquicia_cobrada).to eq("0.0")
    expect(abril.saldo_pendiente_aseguradoras).to eq("0.0")
    expect(abril.ingresos_clientes_directos).to eq("800.0")
    expect(abril.total_ingresos).to eq("800.0")
    expect(mayo.franquicia_cobrada).to eq("2500.0")
    expect(mayo.saldo_facturado_aseguradoras).to eq("0.0")
    expect(mayo.saldo_pendiente_aseguradoras).to eq("7500.0")
    expect(mayo.ingresos_clientes_directos).to eq("0.0")
    expect(mayo.total_ingresos).to eq("2500.0")
  end

  it "incluye los extremos del período y deja afuera el día anterior y el siguiente" do
    al_inicio = con_caso(orden_con_monto)
    cerrar(al_inicio, Time.zone.local(2026, 4, 1, 0, 0, 0), franquicia: 100)

    al_fin = orden_con_monto
    adelantar(al_fin, "200.00", Time.zone.local(2026, 4, 30, 23, 59, 59))

    antes = con_caso(orden_con_monto)
    cerrar(antes, Time.zone.local(2026, 3, 31, 23, 59, 59), franquicia: 400)
    adelantar(orden_con_monto, "400.00", Time.zone.local(2026, 3, 31, 23, 59, 59))

    despues = con_caso(orden_con_monto)
    cerrar(despues, Time.zone.local(2026, 5, 1, 0, 0, 0), franquicia: 800)
    adelantar(orden_con_monto, "800.00", Time.zone.local(2026, 5, 1, 0, 0, 0))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.franquicia_cobrada).to eq("100.0")
    expect(consulta.ingresos_clientes_directos).to eq("200.0")
    expect(consulta.saldo_pendiente_aseguradoras).to eq("9900.0")
    expect(consulta.total_ingresos).to eq("300.0")
  end

  it "deja el saldo pendiente en cero cuando la orden cerrada no tiene caso" do
    orden = orden_con_monto
    adelantar(orden, "1500.00", Time.zone.local(2026, 4, 5, 12))
    cerrar(orden, Time.zone.local(2026, 4, 6, 12), franquicia: 1_500)

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.franquicia_cobrada).to eq("0.0")
    expect(consulta.ingresos_clientes_directos).to eq("1500.0")
    expect(consulta.saldo_pendiente_aseguradoras).to eq("0.0")
    expect(consulta.saldo_facturado_aseguradoras).to eq("0.0")
    expect(consulta.total_ingresos).to eq("1500.0")
  end

  it "cuenta el adelanto de un cliente directo abierto y no el de un caso que sigue abierto" do
    asegurada = con_caso(orden_con_monto(precio: 8_000))
    adelantar(asegurada, "500.00", Time.zone.local(2026, 4, 8, 15))

    directa = orden_con_monto(precio: 4_000)
    adelantar(directa, "700.00", Time.zone.local(2026, 4, 9, 15))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.franquicia_cobrada).to eq("0.0")
    expect(consulta.ingresos_clientes_directos).to eq("700.0")
    expect(consulta.saldo_pendiente_aseguradoras).to eq("0.0")
    expect(consulta.total_ingresos).to eq("700.0")
  end

  it "sigue contando al cliente directo cuando hay un caso todavía sin orden" do
    create(:caso)
    directa = orden_con_monto(precio: 4_000)
    adelantar(directa, "700.00", Time.zone.local(2026, 4, 9, 15))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.ingresos_clientes_directos).to eq("700.0")
    expect(consulta.franquicia_cobrada).to eq("0.0")
    expect(consulta.total_ingresos).to eq("700.0")
  end

  it "usa el total cerrado después de un ajuste y no los adelantos del caso" do
    orden = con_caso(orden_con_monto(precio: 1_000))
    adelantar(orden, "200.00", Time.zone.local(2026, 4, 10, 12))
    repuesto = RepuestoAgregar.call(
      orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 2,
      costo_unitario: "100", margen: "20"
    )
    RepuestoRegistrarAjuste.call(
      repuesto: repuesto, registrado_por: admin, tipo: "devolucion", cantidad: 1,
      costo_unitario: "100", motivo: "Sobra"
    )
    cerrar(orden, Time.zone.local(2026, 4, 11, 12), franquicia: 350)

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.franquicia_cobrada).to eq("350.0")
    expect(consulta.saldo_facturado_aseguradoras).to eq("0.0")
    expect(consulta.saldo_pendiente_aseguradoras).to eq("770.0")
    expect(consulta.ingresos_clientes_directos).to eq("0.0")
    expect(consulta.total_ingresos).to eq("350.0")
  end

  it "devuelve ceros cuando el período no tiene adelantos ni órdenes cerradas" do
    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta).to be_valid
    expect(consulta.franquicia_cobrada).to eq("0.0")
    expect(consulta.saldo_facturado_aseguradoras).to eq("0.0")
    expect(consulta.saldo_pendiente_aseguradoras).to eq("0.0")
    expect(consulta.ingresos_clientes_directos).to eq("0.0")
    expect(consulta.total_ingresos).to eq("0.0")
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
