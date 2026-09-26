require "rails_helper"

RSpec.describe UsuarioResetearPassword do
  let(:usuario) { create(:usuario, password: PasswordsDePrueba::ANTERIOR) }

  it "reemplaza la contraseña del usuario" do
    described_class.call(usuario: usuario, password: PasswordsDePrueba::NUEVA)

    expect(usuario.reload.authenticate(PasswordsDePrueba::NUEVA)).to be_truthy
    expect(usuario.authenticate(PasswordsDePrueba::ANTERIOR)).to be(false)
  end

  it "rechaza una contraseña demasiado corta" do
    expect { described_class.call(usuario: usuario, password: PasswordsDePrueba::CORTA) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza una contraseña vacía" do
    expect { described_class.call(usuario: usuario, password: "") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
