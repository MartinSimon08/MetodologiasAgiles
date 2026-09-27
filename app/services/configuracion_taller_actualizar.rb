class ConfiguracionTallerActualizar
  def self.call(margen_repuestos:)
    ConfiguracionTaller.actual.tap do |configuracion|
      configuracion.update!(margen_repuestos: margen_repuestos)
    end
  end
end
