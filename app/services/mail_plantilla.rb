module MailPlantilla
  BASE_IMAGENES = "https://taller.onlineturnos.ar/mail".freeze
  FUENTE = "'IBM Plex Sans','Segoe UI',Helvetica,Arial,sans-serif".freeze
  MONO = "'IBM Plex Mono',Menlo,Consolas,monospace".freeze
  TINTA = "#181818".freeze
  SUAVE = "#6b6b6b".freeze
  PAPEL = "#efefe4".freeze
  SUPERFICIE = "#fcfcf9".freeze
  NOTA = "#f7f7f1".freeze
  REGLA = "#d7d7d6".freeze
  AMBAR = "#ffcf3f".freeze

  module_function

  def aviso_asegurado(caso:, mensaje:, titulo: "Tu vehículo está listo para retirar")
    vehiculo = caso.vehiculo
    envolver(titulo: titulo, etiqueta: "Caso #{caso.numero_siniestro}") do
      <<~HTML
        #{saludo("Hola #{h(caso.asegurado.nombre)},")}
        #{caja_mensaje(mensaje)}
        #{datos([
          [ "Vehículo", descripcion_vehiculo(vehiculo) ],
          [ "Patente", vehiculo.patente ],
          [ "Caso", caso.numero_siniestro ],
          [ "Aseguradora", caso.aseguradora.nombre ]
        ])}
        #{parrafo("Podés pasar a retirarlo en el horario del taller. Si tenés dudas, respondé este mail.")}
      HTML
    end
  end

  def presupuesto(orden:, caso:, presupuesto:)
    vehiculo = caso.vehiculo
    envolver(titulo: "Presupuesto de la orden ##{orden.id}", etiqueta: "Siniestro #{caso.numero_siniestro}") do
      <<~HTML
        #{saludo("Hola #{h(caso.aseguradora.nombre)},")}
        #{parrafo("Te enviamos el presupuesto del siniestro para su aprobación.")}
        #{datos([
          [ "Orden", "##{orden.id}" ],
          [ "Siniestro", caso.numero_siniestro ],
          [ "Asegurado", caso.asegurado.nombre ],
          [ "Vehículo", "#{descripcion_vehiculo(vehiculo)} · #{vehiculo.patente}" ]
        ])}
        #{items(presupuesto)}
        #{total(presupuesto.total_aseguradora)}
      HTML
    end
  end

  def imagen_url
    "#{ENV['MAIL_IMAGENES_URL'].presence || BASE_IMAGENES}/taller.jpg"
  end

  def h(valor)
    ERB::Util.html_escape(valor.to_s)
  end

  def importe(valor)
    ActiveSupport::NumberHelper.number_to_currency(valor.to_d, unit: "$ ", delimiter: ".", separator: ",", precision: 2)
  end

  def descripcion_vehiculo(vehiculo)
    [ vehiculo.marca, vehiculo.modelo ].compact_blank.join(" ").presence || "Vehículo"
  end

  def saludo(texto)
    %(<p style="margin:0 0 12px;font-size:18px;line-height:27px;color:#{TINTA};">#{texto}</p>)
  end

  def parrafo(texto)
    %(<p style="margin:16px 0 0;font-size:16px;line-height:24px;color:#{SUAVE};">#{h(texto)}</p>)
  end

  def caja_mensaje(mensaje)
    %(<div style="margin:0 0 24px;padding:14px 16px;background:#{NOTA};border-left:4px solid #{AMBAR};font-size:16px;line-height:24px;color:#{TINTA};">#{h(mensaje)}</div>)
  end

  def datos(filas)
    celdas = filas.map do |etiqueta, valor|
      <<~HTML
        <tr>
          <td style="padding:10px 0;border-top:1px solid #{REGLA};font-family:#{MONO};font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:#{SUAVE};width:38%;">#{h(etiqueta)}</td>
          <td style="padding:10px 0;border-top:1px solid #{REGLA};font-size:16px;color:#{TINTA};font-weight:500;">#{h(valor)}</td>
        </tr>
      HTML
    end
    %(<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-bottom:1px solid #{REGLA};">#{celdas.join}</table>)
  end

  def items(presupuesto)
    lineas = presupuesto.tareas.map { |tarea| [ tarea.descripcion, tarea.precio ] } +
             presupuesto.repuestos.map do |repuesto|
               [ "#{repuesto.descripcion} × #{repuesto.cantidad}", repuesto.valorizado? ? repuesto.precio_vigente : nil ]
             end
    return "" if lineas.empty?

    filas = lineas.map do |descripcion, valor|
      <<~HTML
        <tr>
          <td style="padding:8px 0;border-bottom:1px solid #{REGLA};font-size:15px;color:#{TINTA};">#{h(descripcion)}</td>
          <td align="right" style="padding:8px 0;border-bottom:1px solid #{REGLA};font-size:15px;color:#{TINTA};white-space:nowrap;">#{valor ? importe(valor) : '—'}</td>
        </tr>
      HTML
    end
    %(<p style="margin:24px 0 4px;font-family:#{MONO};font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:#{SUAVE};">Detalle</p><table role="presentation" width="100%" cellpadding="0" cellspacing="0">#{filas.join}</table>)
  end

  def total(monto)
    <<~HTML
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:24px;"><tr>
        <td style="background:#{TINTA};padding:18px 20px;font-family:#{MONO};font-size:12px;letter-spacing:.1em;text-transform:uppercase;color:#{SUPERFICIE};">Total para la aseguradora</td>
        <td align="right" style="background:#{TINTA};padding:18px 20px;font-size:24px;font-weight:600;color:#{SUPERFICIE};white-space:nowrap;">#{importe(monto)}</td>
      </tr></table>
    HTML
  end

  def envolver(titulo:, etiqueta:)
    <<~HTML
      <!doctype html>
      <html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>#{h(titulo)}</title></head>
      <body style="margin:0;padding:0;background:#{PAPEL};font-family:#{FUENTE};">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#{PAPEL};"><tr><td align="center" style="padding:24px 12px;">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:100%;max-width:600px;background:#{SUPERFICIE};border:1px solid #{REGLA};">
          <tr><td style="background:#{TINTA};padding:16px 24px;font-family:#{MONO};font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#{SUPERFICIE};">Gestión de Taller</td></tr>
          <tr><td style="line-height:0;"><img src="#{h(imagen_url)}" width="600" alt="Taller mecánico" style="display:block;width:100%;height:auto;border:0;"></td></tr>
          <tr><td style="background:#{AMBAR};padding:9px 24px;font-family:#{MONO};font-size:12px;letter-spacing:.1em;text-transform:uppercase;color:#{TINTA};font-weight:600;">#{h(etiqueta)}</td></tr>
          <tr><td style="padding:32px 24px 8px;">
            <h1 style="margin:0 0 20px;font-size:30px;line-height:34px;font-weight:300;letter-spacing:-.02em;color:#{TINTA};">#{h(titulo)}</h1>
            #{yield}
          </td></tr>
          <tr><td style="padding:24px;border-top:1px solid #{REGLA};font-size:13px;line-height:19px;color:#{SUAVE};">Mensaje enviado por el sistema del taller. Si no esperabas este aviso, podés ignorarlo.</td></tr>
        </table>
      </td></tr></table>
      </body></html>
    HTML
  end

  private_class_method :envolver, :datos, :items, :total, :caja_mensaje, :parrafo, :saludo
end
