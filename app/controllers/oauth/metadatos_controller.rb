module Oauth
  class MetadatosController < ApplicationController
    allow_unauthenticated_access

    def recurso
      actual = Recurso.desde(request)
      render json: {
        resource: actual.mcp,
        authorization_servers: [ actual.emisor ],
        bearer_methods_supported: [ "header" ],
        scopes_supported: [ AccessToken::SCOPE ]
      }
    end

    def servidor
      actual = Recurso.desde(request)
      render json: {
        issuer: actual.emisor,
        authorization_endpoint: "#{actual.emisor}/oauth/authorize",
        token_endpoint: "#{actual.emisor}/oauth/token",
        registration_endpoint: "#{actual.emisor}/oauth/registro",
        response_types_supported: [ "code" ],
        grant_types_supported: %w[authorization_code refresh_token],
        code_challenge_methods_supported: [ "S256" ],
        token_endpoint_auth_methods_supported: [ "none" ],
        scopes_supported: [ AccessToken::SCOPE ],
        client_id_metadata_document_supported: true
      }
    end
  end
end
