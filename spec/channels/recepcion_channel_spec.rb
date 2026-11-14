require "rails_helper"

RSpec.describe RecepcionChannel, type: :channel do
  it "permite suscribirse a un administrador y lo deja escuchando los avisos" do
    stub_connection(current_usuario: create(:usuario, :administrador))
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(RecepcionChannel::STREAM)
  end

  it "rechaza la suscripción de un mecánico" do
    stub_connection(current_usuario: create(:usuario))
    subscribe

    expect(subscription).to be_rejected
  end
end
