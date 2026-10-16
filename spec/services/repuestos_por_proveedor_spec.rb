require "rails_helper"

RSpec.describe RepuestosPorProveedor do
  let(:admin) { create(:usuario, :administrador) }

  def agregar(fecha: nil, **atributos)
    compra = -> {
      RepuestoAgregar.call(orden: create(:orden), registrado_por: admin, descripcion: "Filtro",
                           cantidad: 1, costo_unitario: "100", **atributos)
    }
    fecha ? travel_to(fecha, &compra) : compra.call
  end

  def consultar(**filtros)
    described_class.call(**filtros)
  end

  it "agrupa las compras valorizadas por proveedor y suma el costo real" do
    agregar(proveedor: "Casa Central", cantidad: 2, costo_unitario: "123.45")
    agregar(proveedor: "Casa Central", cantidad: 1, costo_unitario: "50")
    agregar(proveedor: "Repuestos Centro", cantidad: 1, costo_unitario: "80")
    agregar(cantidad: 1, costo_unitario: "10")

    consulta = consultar

    expect(consulta).to be_valid
    expect(consulta.resumen).to eq([
      { proveedor: "Casa Central", total_comprado: "296.9", cantidad_compras: 2 },
      { proveedor: "Repuestos Centro", total_comprado: "80.0", cantidad_compras: 1 },
      { proveedor: nil, total_comprado: "10.0", cantidad_compras: 1 }
    ])
    expect(consulta.total_comprado).to eq("386.9")
  end

  it "filtra por proveedor sin importar mayúsculas y trata los comodines como texto" do
    agregar(proveedor: "Casa Central")
    agregar(proveedor: "Repuestos Centro")
    agregar(proveedor: "Filtro % especial")

    expect(consultar(proveedor: "  CASA ").resumen).to contain_exactly(
      include(proveedor: "Casa Central")
    )
    expect(consultar(proveedor: "%").resumen).to contain_exactly(
      include(proveedor: "Filtro % especial")
    )
  end

  it "filtra por período inclusive según la fecha de carga" do
    agregar(fecha: Time.zone.local(2026, 3, 10, 12), proveedor: "Marzo")
    agregar(fecha: Time.zone.local(2026, 4, 1, 0), proveedor: "Abril")
    agregar(fecha: Time.zone.local(2026, 4, 30, 23, 59, 59), proveedor: "Abril")
    agregar(fecha: Time.zone.local(2026, 5, 1, 0), proveedor: "Mayo")

    consulta = consultar(desde: "2026-04-01", hasta: "2026-04-30")

    expect(consulta.resumen).to contain_exactly(
      include(proveedor: "Abril", cantidad_compras: 2, total_comprado: "200.0")
    )
    expect(consulta.repuestos.map(&:proveedor)).to eq([ "Abril", "Abril" ])
  end

  it "excluye los avisos pendientes de valorizar" do
    agregar(proveedor: "Casa Central")
    RepuestoAvisar.call(orden: create(:orden), registrado_por: create(:usuario),
                        descripcion: "Pastillas", cantidad: 2)

    expect(consultar.resumen).to contain_exactly(include(proveedor: "Casa Central", cantidad_compras: 1))
    expect(consultar.repuestos.map(&:descripcion)).to eq([ "Filtro" ])
  end

  it "devuelve un resumen vacío cuando no hay compras" do
    consulta = consultar(proveedor: "Nadie")

    expect(consulta.resumen).to eq([])
    expect(consulta.total_comprado).to eq("0.0")
    expect(consulta.repuestos).to be_empty
  end

  it "rechaza fechas inválidas o un período invertido" do
    expect(consultar(desde: "15/04/2026").errors).to eq(desde: [ "no es una fecha válida" ])
    expect(consultar(hasta: "no-es-fecha").errors).to eq(hasta: [ "no es una fecha válida" ])
    expect(consultar(desde: "2026-04-30", hasta: "2026-04-01").errors).to eq(
      hasta: [ "debe ser posterior o igual a la fecha desde" ]
    )
    expect(consultar(desde: "2026-04-01", hasta: "2026-04-01")).to be_valid
  end
end
