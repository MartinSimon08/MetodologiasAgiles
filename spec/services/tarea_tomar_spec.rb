require "rails_helper"

RSpec.describe TareaTomar do
  let(:tarea) { create(:tarea) }
  let(:mecanico) { create(:usuario) }

  it "pasa la tarea a en_curso y registra responsable y timestamp" do
    described_class.call(tarea: tarea, mecanico: mecanico)

    tarea.reload
    expect(tarea).to be_en_curso
    expect(tarea.mecanico).to eq(mecanico)
    expect(tarea.tomada_en).to be_within(2.seconds).of(Time.current)
  end

  it "rechaza tomar una tarea que ya está en curso" do
    otro_mecanico = create(:usuario)
    tarea.update!(estado: :en_curso, mecanico: otro_mecanico, tomada_en: Time.current)

    expect { described_class.call(tarea: tarea, mecanico: mecanico) }
      .to raise_error(ActiveRecord::RecordInvalid)

    expect(tarea.reload.mecanico).to eq(otro_mecanico)
  end

  it "rechaza tomar una tarea ya terminada" do
    tarea.update!(estado: :terminada, mecanico: mecanico, tomada_en: 1.hour.ago, terminada_en: Time.current)

    expect { described_class.call(tarea: tarea, mecanico: create(:usuario)) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  context "con dos conexiones reales a la base" do
    self.use_transactional_tests = false

    after do
      Tarea.delete_all
      Orden.delete_all
      Vehiculo.delete_all
      Cliente.delete_all
      Usuario.delete_all
    end

    it "impide que dos mecánicos tomen la misma tarea al mismo tiempo" do
      tarea = create(:tarea)
      mecanico = create(:usuario)
      otro_mecanico = create(:usuario)
      resultados = Queue.new

      hilos = [ mecanico, otro_mecanico ].map do |usuario|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            described_class.call(tarea: tarea, mecanico: usuario)
            resultados << :ok
          rescue ActiveRecord::RecordInvalid
            resultados << :rechazada
          end
        end
      end
      hilos.each(&:join)

      expect(Array.new(2) { resultados.pop }).to contain_exactly(:ok, :rechazada)
      expect(tarea.reload).to be_en_curso
    end
  end
end
