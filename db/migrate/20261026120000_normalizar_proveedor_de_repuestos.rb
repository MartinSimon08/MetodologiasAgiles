class NormalizarProveedorDeRepuestos < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE repuestos
      SET proveedor = NULLIF(BTRIM(REGEXP_REPLACE(proveedor, '[[:space:]]+', ' ', 'g')), '')
      WHERE proveedor IS NOT NULL
        AND proveedor IS DISTINCT FROM NULLIF(BTRIM(REGEXP_REPLACE(proveedor, '[[:space:]]+', ' ', 'g')), '')
    SQL
  end

  def down
  end
end
