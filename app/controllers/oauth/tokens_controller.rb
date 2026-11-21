module Oauth
  class TokensController < ApplicationController
    include RespondeOauth

    allow_unauthenticated_access

    def create
      sin_cache
      render json: EmitirToken.call(params: token_params, recurso: Recurso.desde(request))
    end

    private

    def token_params
      params.permit(:grant_type, :code, :redirect_uri, :client_id, :code_verifier, :refresh_token, :resource, :scope)
    end
  end
end
