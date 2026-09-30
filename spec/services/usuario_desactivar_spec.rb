require "rails_helper"

RSpec.describe UsuarioDesactivar do
  let!(:admin) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  it "desactiva al usuario sin borrarlo" do
    described_class.call(usuario: mecanico)

    expect(mecanico.reload).not_to be_activo
    expect(Usuario.exists?(mecanico.id)).to be(true)
  end

  it "libera las tareas tomadas sin terminar y las informa" do
    tomada = create(:tarea, :en_curso, mecanico: mecanico)
    otra_tomada = create(:tarea, :en_curso, mecanico: mecanico)

    resultado = described_class.call(usuario: mecanico)

    expect(resultado.tareas_liberadas).to contain_exactly(tomada, otra_tomada)
    expect(tomada.reload).to be_pendiente
    expect(tomada.mecanico).to be_nil
    expect(otra_tomada.reload).to be_pendiente
  end

  it "conserva al mecánico en sus tareas terminadas" do
    terminada = create(:tarea, :terminada, mecanico: mecanico)

    resultado = described_class.call(usuario: mecanico)

    expect(resultado.tareas_liberadas).to be_empty
    expect(terminada.reload).to be_terminada
    expect(terminada.mecanico).to eq(mecanico)
  end

  it "no toca las tareas de otros mecánicos" do
    ajena = create(:tarea, :en_curso)

    described_class.call(usuario: mecanico)

    expect(ajena.reload).to be_en_curso
  end

  it "impide desactivar al último administrador activo" do
    expect { described_class.call(usuario: admin) }
      .to raise_error(ActiveRecord::RecordInvalid, /último administrador activo/)
    expect(admin.reload).to be_activo
  end

  it "no cuenta a los administradores desactivados" do
    create(:usuario, :administrador, activo: false)

    expect { described_class.call(usuario: admin) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "permite desactivar a un administrador si queda otro activo" do
    create(:usuario, :administrador)

    described_class.call(usuario: admin)

    expect(admin.reload).not_to be_activo
  end

  it "rechaza desactivar a un usuario ya desactivado" do
    mecanico.update!(activo: false)

    expect { described_class.call(usuario: mecanico) }
      .to raise_error(ActiveRecord::RecordInvalid, /ya está desactivado/)
  end
end
