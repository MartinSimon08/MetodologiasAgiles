module Mcp
  class Fallo < StandardError
    attr_reader :tipo

    def initialize(tipo, mensaje)
      @tipo = tipo
      super(mensaje)
    end
  end
end
