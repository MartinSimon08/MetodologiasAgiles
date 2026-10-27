class ConfiguracionTaller < ApplicationRecord
  self.table_name = "configuraciones_taller"

  validates :margen_repuestos,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  validates :cupo_diario,
            numericality: { only_integer: true, greater_than: 0 }

  def self.actual
    create_or_find_by!(registro_unico: true)
  end
end
