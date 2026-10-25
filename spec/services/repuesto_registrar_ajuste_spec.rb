require "rails_helper"

RSpec.describe RepuestoRegistrarAjuste do
  let(:orden) { create(:orden) }
  let(:admin) { create(:usuario, :administrador) }
  let(:repuesto) do
    RepuestoAgregar.call(
      orden: orden, registrado_por: admin, descripcion: "Filtro", cantidad: 2,
      costo_unitario: "123.45", margen: "20"
    )
  end

  def registrar(**atributos)
    described_class.call(
      repuesto: repuesto, registrado_por: admin, cantidad: 1, costo_unitario: "123.45", motivo: "  Falla de fábrica  ", **atributos
    )
  end

  it "registra una devolución parcial sin modificar el repuesto original" do
    antes = repuesto.attributes

    ajuste = registrar(tipo: "devolucion")

    expect(ajuste).to have_attributes(
      tipo: "devolucion", cantidad: 1, costo_unitario: BigDecimal("123.45"), motivo: "Falla de fábrica",
      precio_original: BigDecimal("148.14"), ajuste_precio_cliente: BigDecimal("-148.14"), ajuste_costo: BigDecimal("-123.45"),
      registrado_por: admin
    )
    expect(ajuste.registrado_en).to be_present
    expect(repuesto.reload.attributes).to eq(antes)
    expect(repuesto.precio_vigente).to eq(BigDecimal("148.14"))
    expect(repuesto.costo_vigente).to eq(BigDecimal("123.45"))
    expect(repuesto.cantidad_disponible).to eq(1)
    expect(orden.reload.total).to eq(BigDecimal("148.14"))
  end

  it "acredita un costo distinto del original y aun así quita el precio al cliente" do
    ajuste = registrar(tipo: "devolucion", costo_unitario: "0")

    expect(ajuste.ajuste_costo).to eq(0)
    expect(ajuste.ajuste_precio_cliente).to eq(BigDecimal("-148.14"))
    expect(repuesto.reload.costo_vigente).to eq(BigDecimal("246.90"))
    expect(repuesto.precio_vigente).to eq(BigDecimal("148.14"))
  end

  it "al devolver todas las unidades deja el precio vigente en cero, sin perder centavos" do
    registrar(tipo: "devolucion")
    registrar(tipo: "devolucion")

    expect(repuesto.reload.precio_vigente).to eq(0)
    expect(repuesto.cantidad_disponible).to eq(0)
    expect(repuesto.precio_cliente).to eq(BigDecimal("296.28"))
    expect(repuesto.ajustes.sum(:precio_original)).to eq(repuesto.precio_cliente)
  end

  it "asigna el resto de centavos a la última porción" do
    pieza = Repuesto.create!(
      orden: orden, descripcion: "Bujía", cantidad: 3, costo_unitario: "1", margen: "0",
      precio_cliente: "10.00", estado: :valorizado, registrado_por: admin
    )

    3.times do
      described_class.call(
        repuesto: pieza, registrado_por: admin, tipo: "devolucion", cantidad: 1, costo_unitario: "1", motivo: "Falla"
      )
    end

    expect(pieza.ajustes.order(:id).pluck(:precio_original)).to eq(
      [ BigDecimal("3.33"), BigDecimal("3.33"), BigDecimal("3.34") ]
    )
    expect(pieza.reload.precio_vigente).to eq(0)
  end

  it "registra un cambio y recalcula el precio con el margen original" do
    antes = repuesto.attributes

    ajuste = registrar(tipo: "cambio", cantidad: 2, costo_unitario: "100")

    expect(ajuste).to have_attributes(
      tipo: "cambio", cantidad: 2, precio_original: BigDecimal("296.28"),
      ajuste_precio_cliente: BigDecimal("-56.28"), ajuste_costo: BigDecimal("-46.90")
    )
    expect(repuesto.reload.attributes).to eq(antes)
    expect(repuesto.precio_vigente).to eq(BigDecimal("240"))
    expect(repuesto.costo_vigente).to eq(BigDecimal("200"))
    expect(repuesto.cantidad_disponible).to eq(0)
    expect(orden.reload.total).to eq(BigDecimal("240"))
  end

  it "conserva el historial de un cambio aunque el costo sea el mismo" do
    ajuste = registrar(tipo: "cambio", costo_unitario: "123.45")

    expect(ajuste.ajuste_precio_cliente).to eq(0)
    expect(ajuste.ajuste_costo).to eq(0)
    expect(repuesto.reload.precio_vigente).to eq(repuesto.precio_cliente)
    expect(repuesto.cantidad_disponible).to eq(1)
  end

  it "rechaza ajustar más unidades que las que siguen disponibles" do
    registrar(tipo: "devolucion")

    expect { registrar(tipo: "cambio", cantidad: 2, costo_unitario: "80") }
      .to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors[:cantidad]).to include("supera las unidades que todavía no se devolvieron ni cambiaron")
      }
    expect(repuesto.reload.cantidad_disponible).to eq(1)
    expect(repuesto.ajustes.count).to eq(1)
  end

  it "rechaza un repuesto pendiente de valorizar" do
    pendiente = RepuestoAvisar.call(orden: orden, registrado_por: create(:usuario), descripcion: "Filtro", cantidad: 1)

    expect {
      described_class.call(
        repuesto: pendiente, registrado_por: admin, tipo: "devolucion", cantidad: 1, costo_unitario: "10", motivo: "Falla"
      )
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:repuesto]).to include("tiene que estar valorizado")
    }
    expect(AjusteRepuesto.count).to eq(0)
  end

  it "rechaza una orden cerrada sin tocar el repuesto ni el total" do
    antes = repuesto.attributes
    total = orden.total
    orden.update!(estado: :cerrada, cerrada_en: Time.current, cerrada_por: admin, total_cerrado: total)

    expect { registrar(tipo: "devolucion") }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:orden]).to include(
        "está cerrada y su total está congelado. Hay que reabrir la orden para corregirlo"
      )
    }
    expect(repuesto.reload.attributes).to eq(antes)
    expect(AjusteRepuesto.count).to eq(0)
    expect(orden.reload.total).to eq(BigDecimal("296.28"))
  end

  it "rechaza un repuesto ya quitado de la orden" do
    RepuestoQuitar.call(repuesto: repuesto, quitado_por: admin)

    expect { registrar(tipo: "devolucion") }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:repuesto]).to include("ya fue quitado de la orden")
    }
    expect(AjusteRepuesto.count).to eq(0)
  end

  it "rechaza una orden cancelada" do
    repuesto
    orden.update!(estado: :cancelada, cancelada_en: Time.current)

    expect { registrar(tipo: "cambio", costo_unitario: "50") }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:orden]).to include("está cancelada")
    }
    expect(AjusteRepuesto.count).to eq(0)
  end

  it "rechaza un ajuste que dejaría el total por debajo de los adelantos" do
    repuesto
    create(:adelanto, orden: orden, importe: "200.00")

    expect { registrar(tipo: "devolucion", cantidad: 2) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors[:base]).to include(
        "El ajuste dejaría el total de la orden por debajo de los adelantos ya registrados"
      )
    }
    expect(orden.reload.saldo).to eq(BigDecimal("96.28"))
    expect(AjusteRepuesto.count).to eq(0)
  end

  it "acepta un ajuste que deja el total igual a los adelantos" do
    repuesto
    create(:adelanto, orden: orden, importe: "148.14")

    expect { registrar(tipo: "devolucion") }.not_to raise_error
    expect(orden.reload.saldo).to eq(0)
  end

  [ { tipo: nil }, { tipo: "otro" }, { cantidad: 0 }, { cantidad: "1.5" }, { costo_unitario: "-1" },
    { costo_unitario: nil }, { motivo: "  " } ].each do |atributos|
    it "rechaza datos inválidos #{atributos.inspect} sin guardar el ajuste" do
      expect { registrar(**atributos) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(AjusteRepuesto.count).to eq(0)
      expect(repuesto.reload.precio_cliente).to eq(BigDecimal("296.28"))
    end
  end

  context "con dos conexiones reales a la base" do
    self.use_transactional_tests = false

    after do
      AjusteRepuesto.delete_all
      Adelanto.delete_all
      Repuesto.delete_all
      Tarea.delete_all
      Orden.delete_all
      Vehiculo.delete_all
      Cliente.delete_all
      Usuario.delete_all
    end

    it "impide que dos devoluciones simultáneas se pasen de la cantidad" do
      repuesto_id = repuesto.id
      resultados = Queue.new

      hilos = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            described_class.call(
              repuesto: Repuesto.find(repuesto_id), registrado_por: Usuario.find(admin.id),
              tipo: "devolucion", cantidad: 2, costo_unitario: "123.45", motivo: "Falla"
            )
            resultados << :ok
          rescue ActiveRecord::RecordInvalid
            resultados << :rechazada
          end
        end
      end
      hilos.each(&:join)

      expect(Array.new(2) { resultados.pop }).to contain_exactly(:ok, :rechazada)
      expect(Repuesto.find(repuesto_id).ajustes.count).to eq(1)
      expect(Repuesto.find(repuesto_id).cantidad_disponible).to eq(0)
    end
  end
end
