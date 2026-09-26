module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate!, **options
    end
  end

  private

  def authenticate!
    head :unauthorized unless current_usuario
  end

  def current_usuario
    return @current_usuario if defined?(@current_usuario)

    payload = JsonWebToken.decode(bearer_token)
    @current_usuario = payload && Usuario.find_by(id: payload["usuario_id"])
  end

  def require_administrador!
    head :forbidden unless current_usuario&.administrador?
  end

  def bearer_token
    request.authorization.to_s[/\ABearer (.+)\z/, 1]
  end
end
