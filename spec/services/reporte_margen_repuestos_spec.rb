require "rails_helper"

RSpec.describe ReporteMargenRepuestos do
  let(:admin) { create(:usuario, :administrador) }

  def consultar(**filtros)
    described_class.call(**filtros)
  end

  def orden_el(momento)
    travel_to(momento) { create(:orden) }
  end

  def cerrar(orden)
    orden.update!(estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin, total_cerrado: orden.total)
  end

  def cargar(orden, costo_unitario:, margen: "20", cantidad: 1, descripcion: "Filtro")
    RepuestoAgregar.call(
      orden: orden, registrado_por: admin, descripcion: descripcion, cantidad: cantidad,
      costo_unitario: costo_unitario, margen: margen
    )
  end

  it "suma el margen de los repuestos valorizados de las órdenes abiertas en el período" do
    abril = orden_el(Time.zone.local(2026, 4, 10, 12))
    otra = orden_el(Time.zone.local(2026, 4, 30, 23, 59, 59))
    cargar(abril, costo_unitario: "100", margen: "25")
    cargar(otra, costo_unitario: "80", margen: "50")
    cerrar(otra)

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta).to be_valid
    expect(consulta.margen_total).to eq("65.0")
  end

  it "incluye un repuesto cargado después si la orden se abrió dentro del período" do
    orden = orden_el(Time.zone.local(2026, 4, 1, 0))
    travel_to(Time.zone.local(2026, 5, 15, 12)) { cargar(orden, costo_unitario: "100", margen: "25") }

    dentro = consultar(desde: "2026-04-01", hasta: "2026-04-30")
    fuera = consultar(desde: "2026-05-01", hasta: "2026-05-31")

    expect(dentro.margen_total).to eq("25.0")
    expect(fuera.margen_total).to eq("0.0")
  end

  it "descuenta devoluciones y cambios del costo y del precio de venta" do
    orden = orden_el(Time.zone.local(2026, 4, 10, 12))
    repuesto = cargar(orden, costo_unitario: "100", margen: "20", cantidad: 2)
    RepuestoRegistrarAjuste.call(
      repuesto: repuesto, registrado_por: admin, tipo: "devolucion", cantidad: 1,
      costo_unitario: "100", motivo: "Sobra"
    )

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.margen_total).to eq("20.0")
  end

  it "no cuenta repuestos rechazados, quitados, sin valorizar ni los de órdenes canceladas" do
    orden = orden_el(Time.zone.local(2026, 4, 10, 12))
    rechazado = cargar(orden, costo_unitario: "100", margen: "25", descripcion: "Rechazado")
    quitado = cargar(orden, costo_unitario: "100", margen: "25", descripcion: "Quitado")
    RepuestoRegistrarAprobacion.call(repuesto: rechazado, aprobacion: "rechazado")
    RepuestoQuitar.call(repuesto: quitado, quitado_por: admin)
    RepuestoAvisar.call(orden: orden, registrado_por: admin, descripcion: "Sin precio", cantidad: 1)

    cancelada = orden_el(Time.zone.local(2026, 4, 12, 12))
    cargar(cancelada, costo_unitario: "100", margen: "25")
    cancelada.update!(estado: :cancelada, cancelada_en: Time.zone.local(2026, 4, 12, 13))

    afuera = orden_el(Time.zone.local(2026, 3, 31, 23, 59, 59))
    cargar(afuera, costo_unitario: "100", margen: "25")

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.margen_total).to eq("0.0")
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
