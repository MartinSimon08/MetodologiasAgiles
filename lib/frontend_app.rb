class FrontendApp
  ASSETS_PREFIX = "/assets/".freeze
  CACHE_ASSETS = "public, max-age=31536000, immutable".freeze
  CACHE_PAGINA = "no-cache".freeze
  TIPO_MARKDOWN = "text/markdown; charset=utf-8".freeze
  TIPO_CATALOGO = 'application/linkset+json;profile="https://www.rfc-editor.org/info/rfc9727"'.freeze
  CATALOGO = "/.well-known/api-catalog".freeze

  RUTAS_SPA = [
    %r{\A/\z},
    %r{\A/login\z},
    %r{\A/mis-tareas\z},
    %r{\A/ordenes\z},
    %r{\A/ordenes/[^/]+\z},
    %r{\A/repuestos\z},
    %r{\A/repuestos/proveedores\z},
    %r{\A/clientes\z},
    %r{\A/vehiculos\z},
    %r{\A/vehiculos/[^/]+/historial\z},
    %r{\A/casos\z},
    %r{\A/aseguradoras\z},
    %r{\A/usuarios\z},
    %r{\A/tareas-frecuentes\z},
    %r{\A/configuracion\z}
  ].freeze

  PAGINAS = {
    "/about" => "about",
    "/contact" => "contact",
    "/privacy" => "privacy",
    "/docs" => "docs"
  }.freeze

  MARKDOWN_APP = <<~MD.freeze
    # Gestión de Taller

    Esta pantalla es de la aplicación y pide sesión. Sin cuenta no se ven clientes, vehículos ni órdenes.

    - [Inicio](/)
    - [Documentación de la API](/docs)
    - [Mapa del sitio](/sitemap.xml)
    - [llms.txt](/llms.txt)
  MD

  def initialize(root)
    @root = root
    @files = Rack::Files.new(root)
  end

  def call(env)
    path = normalizar(env[Rack::PATH_INFO])
    env = env.merge(Rack::PATH_INFO => path)

    return responder_archivo(env, inmutable: true) if asset?(path)
    return responder_catalogo(env) if path == CATALOGO
    return responder_archivo(env, inmutable: false) if archivo_estatico?(path)

    preferencia = preferencia_de(env["HTTP_ACCEPT"])
    return no_aceptable(env) if preferencia == :ninguna
    return responder_markdown(env, path) if preferencia == :markdown && markdown?(path)
    return responder_index(env) if ruta_spa?(path)
    return responder_pagina(env, PAGINAS[path]) if PAGINAS.key?(path)

    no_encontrado(env, preferencia)
  end

  private

  def asset?(path)
    path.start_with?(ASSETS_PREFIX)
  end

  def ruta_spa?(path)
    RUTAS_SPA.any? { |ruta| ruta.match?(path) }
  end

  def markdown?(path)
    path == "/" || PAGINAS.key?(path) || ruta_spa?(path)
  end

  def normalizar(path)
    ruta = path.to_s
    ruta = "/#{ruta}" unless ruta.start_with?("/")
    ruta = ruta.sub(%r{/+\z}, "") unless ruta == "/"
    ruta.empty? ? "/" : ruta
  end

  def archivo_estatico?(path)
    return false if path == "/" || path.include?("..")

    File.file?(File.join(@root, path.delete_prefix("/")))
  end

  def preferencia_de(accept)
    header = accept.to_s.strip
    return :html if header.empty?

    rangos = header.split(",").filter_map { |parte| parsear_rango(parte) }
    q_html = calidad(rangos, "text/html")
    q_markdown = calidad(rangos, "text/markdown")
    return :ninguna if q_html <= 0 && q_markdown <= 0

    q_markdown > q_html ? :markdown : :html
  end

  def parsear_rango(parte)
    trozos = parte.split(";").map(&:strip)
    tipo = trozos.shift.to_s.downcase
    return if tipo.empty?

    q = 1.0
    trozos.each do |parametro|
      clave, valor = parametro.split("=", 2)
      q = valor.to_f if clave&.downcase == "q" && valor
    end
    { tipo: tipo, q: q.clamp(0.0, 1.0) }
  end

  def calidad(rangos, media)
    tipo, = media.split("/", 2)
    mejor_especificidad = -1
    mejor_q = 0.0

    rangos.each do |rango|
      especificidad = especificidad_de(rango[:tipo], media, tipo)
      next if especificidad.negative?
      next if especificidad < mejor_especificidad

      if especificidad > mejor_especificidad
        mejor_especificidad = especificidad
        mejor_q = rango[:q]
      elsif rango[:q] > mejor_q
        mejor_q = rango[:q]
      end
    end

    mejor_q
  end

  def especificidad_de(rango, media, tipo)
    rango_tipo, rango_subtipo = rango.split("/", 2)
    if rango == media
      3
    elsif rango_tipo == tipo && rango_subtipo == "*"
      2
    elsif rango == "*/*"
      1
    else
      -1
    end
  end

  def responder_archivo(env, inmutable:)
    status, headers, body = @files.call(env)
    headers["cache-control"] = inmutable && status == 200 ? CACHE_ASSETS : CACHE_PAGINA
    [ status, headers, body ]
  end

  def responder_catalogo(env)
    status, headers, body = @files.call(env)
    return no_encontrado(env, preferencia_de(env["HTTP_ACCEPT"])) if status == 404

    headers["content-type"] = TIPO_CATALOGO
    headers["cache-control"] = CACHE_PAGINA
    [ status, headers, body ]
  end

  def responder_index(env)
    status, headers, body = @files.call(env.merge(Rack::PATH_INFO => "/index.html"))
    headers["cache-control"] = CACHE_PAGINA
    headers["vary"] = "Accept"
    [ status, headers, body ]
  end

  def responder_pagina(env, nombre)
    status, headers, body = @files.call(env.merge(Rack::PATH_INFO => "/#{nombre}.html"))
    return no_encontrado(env, :html) if status == 404

    headers["cache-control"] = CACHE_PAGINA
    headers["vary"] = "Accept"
    [ status, headers, body ]
  end

  def responder_markdown(env, path)
    cuerpo = cuerpo_markdown(path)
    return no_encontrado(env, :markdown) if cuerpo.nil?

    responder_cuerpo(env, 200, TIPO_MARKDOWN, cuerpo)
  end

  def cuerpo_markdown(path)
    return MARKDOWN_APP if ruta_spa?(path) && path != "/"

    nombre = path == "/" ? "home.md" : "#{PAGINAS[path]}.md"
    completo = File.join(@root, nombre)
    return unless File.file?(completo)

    File.binread(completo).force_encoding(Encoding::UTF_8)
  end

  def no_encontrado(env, preferencia)
    return no_aceptable(env) if preferencia == :ninguna

    if preferencia == :markdown
      responder_cuerpo(env, 404, TIPO_MARKDOWN, markdown_no_encontrado(env[Rack::PATH_INFO]))
    else
      responder_cuerpo(env, 404, "text/html; charset=utf-8", html_no_encontrado(env[Rack::PATH_INFO]))
    end
  end

  def no_aceptable(env)
    responder_cuerpo(
      env,
      406,
      "text/plain; charset=utf-8",
      "Esta página se sirve como text/html o text/markdown.\n"
    )
  end

  def responder_cuerpo(env, status, content_type, cuerpo)
    cuerpo = cuerpo.dup.force_encoding(Encoding::UTF_8)
    [
      status,
      {
        "content-type" => content_type,
        "cache-control" => CACHE_PAGINA,
        "vary" => "Accept",
        "content-length" => cuerpo.bytesize.to_s
      },
      env["REQUEST_METHOD"] == "HEAD" ? [] : [ cuerpo ]
    ]
  end

  def markdown_no_encontrado(path)
    visible = ruta_visible(path).delete("`")
    <<~MD
      # No encontrado

      La ruta `#{visible}` no existe en Gestión de Taller.

      - [Inicio](/)
      - [Documentación de la API](/docs)
      - [Mapa del sitio](/sitemap.xml)
      - [llms.txt](/llms.txt)
    MD
  end

  def html_no_encontrado(path)
    visible = Rack::Utils.escape_html(ruta_visible(path))
    <<~HTML
      <!doctype html>
      <html lang="es">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>No encontrado · Gestión de Taller</title>
          <link rel="stylesheet" href="/publico.css" />
        </head>
        <body>
          <main class="publico">
            <p class="kicker">Gestión de Taller</p>
            <h1>No encontrado</h1>
            <p>La ruta #{visible} no existe.</p>
            <nav aria-label="Páginas públicas">
              <a href="/">Inicio</a>
              <a href="/docs">Documentación</a>
              <a href="/sitemap.xml">Mapa del sitio</a>
              <a href="/llms.txt">llms.txt</a>
            </nav>
          </main>
        </body>
      </html>
    HTML
  end

  def ruta_visible(path)
    path.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace).gsub(/[[:cntrl:]]/, "")[0, 200]
  end
end
