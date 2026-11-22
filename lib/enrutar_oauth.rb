class EnrutarOauth
  PREFIJOS = %w[
    /.well-known/oauth-protected-resource
    /.well-known/oauth-authorization-server
    /.well-known/openid-configuration
  ].freeze

  def initialize(frontend, api)
    @frontend = frontend
    @api = api
  end

  def call(env)
    path = env[Rack::PATH_INFO].to_s
    if PREFIJOS.any? { |prefijo| path == prefijo || path.start_with?("#{prefijo}/") }
      @api.call(env)
    else
      @frontend.call(env)
    end
  end
end
