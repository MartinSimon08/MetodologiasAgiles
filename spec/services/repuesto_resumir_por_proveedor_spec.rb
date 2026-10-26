require "rails_helper"

RSpec.describe RepuestoResumirPorProveedor do
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

  it "no cuenta las compras quitadas" do
    vigente = agregar(proveedor: "Casa Central", costo_unitario: "40")
    quitada = agregar(proveedor: "Casa Central", costo_unitario: "70")
    RepuestoQuitar.call(repuesto: quitada, quitado_por: admin)

    consulta = consultar

    expect(consulta.resumen).to eq([
      { proveedor: "Casa Central", total_comprado: "40.0", cantidad_compras: 1 }
    ])
    expect(consulta.total_comprado).to eq("40.0")
    expect(consulta.repuestos).to contain_exactly(vigente)
  end

  it "agrupa el mismo proveedor sin distinguir mayúsculas, espacios ni tildes" do
    agregar(proveedor: "Casa Central", costo_unitario: "10")
    agregar(proveedor: "casa central", costo_unitario: "20")
    agregar(proveedor: " Casa  Central ", costo_unitario: "30")
    agregar(proveedor: "Rodríguez", costo_unitario: "40")
    agregar(proveedor: "Rodriguez", costo_unitario: "50")
    agregar(proveedor: "   ", costo_unitario: "5")
    agregar(costo_unitario: "7")

    expect(consultar.resumen).to contain_exactly(
      { proveedor: "Rodriguez", cantidad_compras: 2, total_comprado: "90.0" },
      { proveedor: "Casa Central", cantidad_compras: 3, total_comprado: "60.0" },
      { proveedor: nil, cantidad_compras: 2, total_comprado: "12.0" }
    )
  end

  it "descuenta las devoluciones y suma la diferencia de los cambios" do
    devuelto = agregar(proveedor: "Casa Central", cantidad: 2, costo_unitario: "100", margen: "20")
    RepuestoRegistrarAjuste.call(repuesto: devuelto, registrado_por: admin, tipo: "devolucion",
                                 cantidad: 1, costo_unitario: "100", motivo: "Sobró uno")
    cambiado = agregar(proveedor: "Casa Central", cantidad: 1, costo_unitario: "50", margen: "20")
    RepuestoRegistrarAjuste.call(repuesto: cambiado, registrado_por: admin, tipo: "cambio",
                                 cantidad: 1, costo_unitario: "80", motivo: "Otra marca")

    consulta = consultar

    expect(consulta.resumen).to eq([
      { proveedor: "Casa Central", total_comprado: "180.0", cantidad_compras: 2 }
    ])
    expect(consulta.total_comprado).to eq("180.0")
    expect(consulta.repuestos.map { |repuesto| described_class.total_linea(repuesto) }).to eq([ "80.0", "100.0" ])
  end

  it "no cuenta las compras de órdenes canceladas" do
    agregar(proveedor: "Casa Central", costo_unitario: "40")
    cancelada = agregar(proveedor: "Casa Central", costo_unitario: "70")
    OrdenCancelar.call(orden: cancelada.orden)

    consulta = consultar

    expect(consulta.resumen).to eq([
      { proveedor: "Casa Central", total_comprado: "40.0", cantidad_compras: 1 }
    ])
    expect(consulta.total_comprado).to eq("40.0")
    expect(consulta.repuestos).not_to include(cancelada)
  end

  it "guarda el proveedor sin espacios de más y convierte el vacío en nulo" do
    expect(agregar(proveedor: "  Casa   Central ").proveedor).to eq("Casa Central")
    expect(agregar(proveedor: "   ").proveedor).to be_nil
  end

  it "filtra por proveedor sin importar mayúsculas ni tildes y trata los comodines como texto" do
    agregar(proveedor: "Casa Central")
    agregar(proveedor: "Repuestos Centro")
    agregar(proveedor: "Filtro % especial")
    agregar(proveedor: "Rodríguez")

    expect(consultar(proveedor: "  CASA ").resumen).to contain_exactly(
      include(proveedor: "Casa Central")
    )
    expect(consultar(proveedor: "rodriguez").resumen).to contain_exactly(
      include(proveedor: "Rodríguez")
    )
    expect(consultar(proveedor: "RODRÍ").resumen).to contain_exactly(
      include(proveedor: "Rodríguez")
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
