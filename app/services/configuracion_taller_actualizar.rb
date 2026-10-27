class ConfiguracionTallerActualizar
  def self.call(**atributos)
    ConfiguracionTaller.actual.tap do |configuracion|
      configuracion.update!(atributos)
    end
  end
end
