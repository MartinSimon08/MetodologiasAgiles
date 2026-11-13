require "rails_helper"

RSpec.describe ReporteOrdenesPorPeriodo do
  let(:admin) { create(:usuario, :administrador) }

  def consultar(**filtros)
    described_class.call(**filtros)
  end

  def orden_el(momento)
    travel_to(momento) { create(:orden) }
  end

  def cerrar(orden, momento)
    orden.update!(estado: :cerrada, cerrada_en: momento, cerrada_por: admin, total_cerrado: 0)
  end

  it "cuenta las órdenes abiertas en el período, incluidos el primer y el último instante" do
    orden_el(Time.zone.local(2026, 4, 1, 0))
    orden_el(Time.zone.local(2026, 4, 30, 23, 59, 59))
    orden_el(Time.zone.local(2026, 3, 31, 23, 59, 59))
    orden_el(Time.zone.local(2026, 5, 1, 0))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta).to be_valid
    expect(consulta.abiertas).to eq(2)
  end

  it "cuenta las órdenes cerradas según su fecha de cierre y no la de apertura" do
    marzo = orden_el(Time.zone.local(2026, 3, 20, 12))
    cerrar(marzo, Time.zone.local(2026, 4, 5, 12))
    abril = orden_el(Time.zone.local(2026, 4, 10, 12))
    cerrar(abril, Time.zone.local(2026, 5, 2, 12))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.abiertas).to eq(1)
    expect(consulta.cerradas).to eq(1)
  end

  it "no cuenta como cerradas las órdenes canceladas ni las que siguen abiertas" do
    cancelada = orden_el(Time.zone.local(2026, 4, 10, 12))
    cancelada.update!(estado: :cancelada, cancelada_en: Time.zone.local(2026, 4, 11, 12))
    orden_el(Time.zone.local(2026, 4, 12, 12))

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.abiertas).to eq(2)
    expect(consulta.cerradas).to eq(0)
  end

  it "devuelve cero cuando no hay órdenes en el período" do
    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta).to have_attributes(abiertas: 0, cerradas: 0)
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
