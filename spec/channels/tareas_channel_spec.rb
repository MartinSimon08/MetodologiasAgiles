require "rails_helper"

RSpec.describe TareasChannel, type: :channel do
  it "permite suscribirse a un mecánico y lo deja escuchando las tareas disponibles" do
    stub_connection(current_usuario: create(:usuario))
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(TareasChannel::STREAM)
  end

  it "rechaza la suscripción de un administrador" do
    stub_connection(current_usuario: create(:usuario, :administrador))
    subscribe

    expect(subscription).to be_rejected
  end
end
