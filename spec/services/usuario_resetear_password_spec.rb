require "rails_helper"

RSpec.describe UsuarioResetearPassword do
  let(:usuario) { create(:usuario, password: "anterior123") }

  it "reemplaza la contraseña del usuario" do
    described_class.call(usuario: usuario, password: "nueva12345")

    expect(usuario.reload.authenticate("nueva12345")).to be_truthy
    expect(usuario.authenticate("anterior123")).to be(false)
  end

  it "rechaza una contraseña demasiado corta" do
    expect { described_class.call(usuario: usuario, password: "corta") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rechaza una contraseña vacía" do
    expect { described_class.call(usuario: usuario, password: "") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
