require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:usuario) { create(:usuario) }

  it "conecta identificando al usuario dueño de un token válido" do
    connect "/cable?token=#{JsonWebToken.para(usuario)}"

    expect(connection.current_usuario).to eq(usuario)
  end

  it "rechaza la conexión sin token" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rechaza la conexión con un token inválido" do
    expect { connect "/cable?token=invalido" }.to have_rejected_connection
  end

  it "rechaza la conexión de un usuario desactivado" do
    usuario.update!(activo: false)

    expect { connect "/cable?token=#{JsonWebToken.para(usuario)}" }.to have_rejected_connection
  end
end
