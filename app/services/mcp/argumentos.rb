module Mcp
  class Argumentos
    def initialize(valor)
      @datos = valor.is_a?(Hash) ? valor.stringify_keys : {}
    end

    def texto(clave, obligatorio: false)
      valor = @datos[clave.to_s]
      if valor.nil? || valor == ""
        raise Fallo.new(:parametros, "Falta #{clave}.") if obligatorio

        return
      end
      raise Fallo.new(:parametros, "#{clave} tiene que ser texto.") unless valor.is_a?(String)

      valor
    end

    def entero(clave, obligatorio: false)
      valor = @datos[clave.to_s]
      if valor.nil?
        raise Fallo.new(:parametros, "Falta #{clave}.") if obligatorio

        return
      end
      unless valor.is_a?(Integer) || (valor.is_a?(String) && valor.match?(/\A[1-9]\d*\z/))
        raise Fallo.new(:parametros, "#{clave} tiene que ser un número entero.")
      end

      Integer(valor)
    end

    def decimal(clave, obligatorio: false)
      valor = @datos[clave.to_s]
      if valor.nil? || valor == ""
        raise Fallo.new(:parametros, "Falta #{clave}.") if obligatorio

        return
      end

      texto = case valor
      when Integer then valor.to_s
      when Float then BigDecimal(valor.to_s).to_s("F")
      when BigDecimal then valor.to_s("F")
      when String then valor.strip
      else
        raise Fallo.new(:parametros, "#{clave} tiene que ser un número.")
      end
      raise Fallo.new(:parametros, "#{clave} tiene que ser un número.") unless texto.match?(/\A\d+(\.\d+)?\z/)

      BigDecimal(texto)
    end

    def booleano(clave)
      valor = @datos[clave.to_s]
      return false if valor.nil?
      raise Fallo.new(:parametros, "#{clave} tiene que ser verdadero o falso.") unless valor == true || valor == false

      valor
    end

    def opcion(clave, opciones)
      valor = texto(clave)
      return if valor.nil?
      raise Fallo.new(:parametros, "#{clave} tiene que ser #{opciones.join(' o ')}.") unless opciones.include?(valor)

      valor
    end
  end
end
