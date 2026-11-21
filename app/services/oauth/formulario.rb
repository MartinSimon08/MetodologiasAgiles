require "erb"

module Oauth
  class Formulario
    def self.acceso(accion:, cliente:, redirect_uri:, campos:, error: nil)
      new(accion, cliente, redirect_uri, campos, error).acceso
    end

    def self.error(mensaje)
      documento("No se puede autorizar", "<p>#{ERB::Util.html_escape(mensaje)}</p>")
    end

    def self.documento(titulo, cuerpo)
      <<~HTML
        <!DOCTYPE html>
        <html lang="es">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{ERB::Util.html_escape(titulo)}</title>
          <style>
            body { font-family: system-ui, sans-serif; margin: 2rem auto; max-width: 28rem; line-height: 1.4; }
            label { display: block; margin: 1rem 0; }
            input { display: block; width: 100%; margin-top: 0.25rem; }
            button { margin-top: 0.5rem; }
          </style>
        </head>
        <body>
          <main>
            <h1>#{ERB::Util.html_escape(titulo)}</h1>
            #{cuerpo}
          </main>
        </body>
        </html>
      HTML
    end

    def initialize(accion, cliente, redirect_uri, campos, error)
      @accion = accion
      @cliente = cliente
      @redirect_uri = redirect_uri
      @campos = campos
      @error = error
    end

    def acceso
      aviso = @error.present? ? %(<p role="alert">#{escape(@error)}</p>) : ""
      cuerpo = <<~HTML
        <p>#{escape(@cliente.nombre)} va a operar el taller con tu usuario.</p>
        <p>Después el navegador vuelve a #{destino}.</p>
        #{aviso}
        <form method="post" action="#{escape(@accion)}">
          #{ocultos}
          <label>Email <input type="email" name="email" autocomplete="username" required></label>
          <label>Contraseña <input type="password" name="password" autocomplete="current-password" required></label>
          <button type="submit">Entrar y autorizar</button>
        </form>
      HTML
      self.class.documento("Autorizar acceso al taller", cuerpo)
    end

    private

    def destino
      parsed = URI.parse(@redirect_uri)
      host = parsed.host
      return escape(@redirect_uri) if host.blank?

      escape("#{parsed.scheme}://#{host}")
    rescue URI::InvalidURIError
      escape(@redirect_uri)
    end

    def ocultos
      @campos.map { |clave, valor|
        %(<input type="hidden" name="#{escape(clave)}" value="#{escape(valor)}">)
      }.join
    end

    def escape(valor)
      ERB::Util.html_escape(valor.to_s)
    end
  end
end
