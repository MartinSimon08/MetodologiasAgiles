class FrontendApp
  ASSETS_PREFIX = "/assets/".freeze
  CACHE_ASSETS = "public, max-age=31536000, immutable".freeze
  CACHE_PAGINA = "no-cache".freeze

  def initialize(root)
    @files = Rack::Files.new(root)
  end

  def call(env)
    status, headers, body = @files.call(env)

    if status == 404 && !asset?(env)
      status, headers, body = @files.call(env.merge(Rack::PATH_INFO => "/index.html"))
    end

    headers["cache-control"] = asset?(env) && status == 200 ? CACHE_ASSETS : CACHE_PAGINA
    [ status, headers, body ]
  end

  private

  def asset?(env)
    env[Rack::PATH_INFO].to_s.start_with?(ASSETS_PREFIX)
  end
end
