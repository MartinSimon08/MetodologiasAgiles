require "rails_helper"

RSpec.describe RepuestoAdjuntarComprobante do
  let(:orden) { create(:orden) }
  let(:mecanico) { create(:usuario) }
  let(:admin) { create(:usuario, :administrador) }
  let(:repuesto) { RepuestoAvisar.call(orden: orden, registrado_por: mecanico, descripcion: "Filtro", cantidad: 1) }

  def adjuntar(archivo)
    described_class.call(repuesto: repuesto, archivo: archivo)
  end

  it "guarda la foto en el repuesto de la orden" do
    adjuntar(archivo_comprobante)

    expect(repuesto.comprobante).to be_attached
    expect(repuesto.comprobante.filename.to_s).to eq("comprobante.png")
    expect(repuesto.comprobante.content_type).to eq("image/png")
    expect(orden.repuestos.find(repuesto.id).comprobante.download).to eq(
      File.binread(Rails.root.join("spec/fixtures/files/comprobante.png"))
    )
  end

  %w[comprobante.jpg comprobante.webp].each do |nombre|
    it "acepta #{nombre}" do
      adjuntar(archivo_comprobante(nombre))

      expect(repuesto.comprobante).to be_attached
      expect(repuesto.comprobante.filename.to_s).to eq(nombre)
    end
  end

  it "reemplaza la foto anterior" do
    adjuntar(archivo_comprobante)
    adjuntar(archivo_comprobante("comprobante.jpg"))

    expect(repuesto.comprobante.filename.to_s).to eq("comprobante.jpg")
    expect(repuesto.comprobante.content_type).to eq("image/jpeg")
  end

  it "rechaza una foto de más de 8 MB sin guardarla" do
    archivo = StringIO.new("x")
    archivo.define_singleton_method(:original_filename) { "grande.png" }
    archivo.define_singleton_method(:content_type) { "image/png" }
    archivo.define_singleton_method(:size) { 8.megabytes + 1 }

    expect { adjuntar(archivo) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:comprobante]).to include("no puede superar 8 MB")
    }
    expect(repuesto.reload.comprobante).not_to be_attached
  end

  it "rechaza un archivo vacío" do
    archivo = StringIO.new("")
    archivo.define_singleton_method(:original_filename) { "vacio.png" }
    archivo.define_singleton_method(:content_type) { "image/png" }

    expect { adjuntar(archivo) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:comprobante]).to include("no puede estar en blanco")
    }
    expect(repuesto.comprobante).not_to be_attached
  end

  it "rechaza un pedido sin archivo" do
    expect { adjuntar(nil) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:comprobante]).to include("no puede estar en blanco")
    }
  end

  it "rechaza un archivo que no es JPG, PNG ni WebP" do
    expect { adjuntar(archivo_texto) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:comprobante]).to include("tiene que ser JPG, PNG o WebP")
    }
    expect(repuesto.reload.comprobante).not_to be_attached
  end

  it "rechaza la foto si la orden está cerrada" do
    repuesto
    marcar_cerrada(orden)

    expect { adjuntar(archivo_comprobante) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:orden]).to include("está cerrada")
    }
    expect(repuesto.reload.comprobante).not_to be_attached
  end

  it "rechaza la foto si la orden está cancelada" do
    repuesto
    orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { adjuntar(archivo_comprobante) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:orden]).to include("está cancelada")
    }
    expect(repuesto.reload.comprobante).not_to be_attached
  end

  it "rechaza una foto nueva si el repuesto fue quitado" do
    RepuestoQuitar.call(repuesto: repuesto, quitado_por: admin)

    expect { adjuntar(archivo_comprobante) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:estado]).to include("ya fue quitado de la orden")
    }
    expect(repuesto.reload.comprobante).not_to be_attached
  end
end
