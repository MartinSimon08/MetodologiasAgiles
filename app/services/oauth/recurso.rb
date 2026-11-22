require "uri"

module Oauth
  class Recurso
    def self.desde(request)
      new("#{request.base_url}#{prefijo_de(request)}")
    end

    def self.prefijo_de(request)
      script = request.script_name.to_s.sub(%r{/+\z}, "")
      return script if script.present?
      return "/api" if ENV["FRONTEND_DIST_PATH"].present?

      ""
    end

    def self.canonico(valor)
      uri = URI.parse(valor.to_s)
      return unless uri.is_a?(URI::HTTP) && uri.host.present?
      return if uri.fragment.present?

      uri.scheme = uri.scheme.downcase
      uri.host = uri.host.downcase
      uri.query = nil
      uri.path = uri.path.to_s.sub(%r{/+\z}, "")
      uri.path = "" if uri.path == "/"
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def self.iguales?(izquierda, derecha)
      return false if izquierda.nil? || derecha.nil?

      izquierda = izquierda.to_s
      derecha = derecha.to_s
      return false unless izquierda.bytesize == derecha.bytesize

      ActiveSupport::SecurityUtils.secure_compare(izquierda, derecha)
    end

    def initialize(base)
      @base = base.to_s.sub(%r{/+\z}, "")
    end

    def emisor
      @base
    end

    def mcp
      self.class.canonico("#{@base}/mcp")
    end

    private_class_method :prefijo_de
  end
end
