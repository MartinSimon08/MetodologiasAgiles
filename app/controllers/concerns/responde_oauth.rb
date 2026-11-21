module RespondeOauth
  extend ActiveSupport::Concern

  included do
    rescue_from Oauth::Error, with: :render_oauth_error
  end

  private

  def render_oauth_error(error)
    response.set_header("Cache-Control", "no-store")
    response.set_header("Pragma", "no-cache")
    render json: { error: error.codigo, error_description: error.message }, status: error.http
  end

  def sin_cache
    response.set_header("Cache-Control", "no-store")
    response.set_header("Pragma", "no-cache")
  end
end
