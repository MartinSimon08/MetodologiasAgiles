module Oauth
  class RegistrosController < ApplicationController
    include RespondeOauth

    allow_unauthenticated_access

    def create
      sin_cache
      render json: RegistrarCliente.call(params), status: :created
    end
  end
end
