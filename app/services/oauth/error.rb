module Oauth
  class Error < StandardError
    attr_reader :codigo, :http

    def initialize(codigo, descripcion, http: :bad_request)
      @codigo = codigo
      @http = http
      super(descripcion)
    end
  end
end
