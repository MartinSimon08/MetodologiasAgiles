module Oauth
  class AutorizacionesController < ApplicationController
    allow_unauthenticated_access

    def new
      responder Autorizar.formulario(params: peticion, recurso: recurso, accion: accion)
    end

    def create
      responder Autorizar.conceder(
        params: peticion.merge("email" => params[:email], "password" => params[:password]),
        recurso: recurso,
        accion: accion
      )
    end

    private

    def peticion
      params.permit(
        :response_type, :client_id, :redirect_uri, :code_challenge, :code_challenge_method,
        :state, :resource, :scope
      ).to_h
    end

    def recurso
      Recurso.desde(request)
    end

    def accion
      "#{request.script_name}/oauth/authorize"
    end

    def responder(resultado)
      response.set_header("Cache-Control", "no-store")
      response.set_header("Referrer-Policy", "no-referrer")
      response.set_header("X-Frame-Options", "DENY")
      response.set_header("Content-Security-Policy", "frame-ancestors 'none'")
      if resultado.redireccion
        response.set_header("Location", resultado.redireccion)
        head :found
      else
        render body: resultado.html, content_type: "text/html; charset=utf-8", status: resultado.estado
      end
    end
  end
end
