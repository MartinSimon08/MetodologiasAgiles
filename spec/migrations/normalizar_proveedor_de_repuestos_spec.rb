require "rails_helper"
require Rails.root.join("db/migrate/20261026120000_normalizar_proveedor_de_repuestos")

RSpec.describe NormalizarProveedorDeRepuestos do
  let(:admin) { create(:usuario, :administrador) }

  def repuesto_con_proveedor(proveedor)
    repuesto = RepuestoAgregar.call(orden: create(:orden), registrado_por: admin, descripcion: "Filtro",
                                    cantidad: 1, costo_unitario: "10", proveedor: "x")
    repuesto.update_column(:proveedor, proveedor)
    repuesto
  end

  it "quita los espacios de más y convierte el proveedor vacío en nulo" do
    con_espacios = repuesto_con_proveedor("  Casa \t Central ")
    vacio = repuesto_con_proveedor("   ")
    sin_cambios = repuesto_con_proveedor("Rodríguez")

    ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) }

    expect(con_espacios.reload.proveedor).to eq("Casa Central")
    expect(vacio.reload.proveedor).to be_nil
    expect(sin_cambios.reload.proveedor).to eq("Rodríguez")
  end
end
