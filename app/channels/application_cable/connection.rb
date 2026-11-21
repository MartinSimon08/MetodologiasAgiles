module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_usuario

    def connect
      self.current_usuario = autenticar!
    end

    private

    def autenticar!
      payload = JsonWebToken.decode(request.params[:token])
      payload = nil unless JsonWebToken.de_sesion?(payload)
      usuario = payload && Usuario.activos.find_by(id: payload["usuario_id"])
      usuario || reject_unauthorized_connection
    end
  end
end
