module ComprobantesDePrueba
  def archivo_comprobante(nombre = "comprobante.png", tipo: nil)
    tipo ||= tipo_de_comprobante(nombre)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/#{nombre}"), tipo, original_filename: nombre)
  end

  def archivo_texto
    path = Rails.root.join("tmp/no-es-imagen.txt")
    File.write(path, "esto no es una foto")
    Rack::Test::UploadedFile.new(path, "image/jpeg", original_filename: "ticket.jpg")
  end

  def tipo_de_comprobante(nombre)
    case File.extname(nombre)
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".webp" then "image/webp"
    else "image/png"
    end
  end
end

RSpec.configure do |config|
  config.include ComprobantesDePrueba
end
