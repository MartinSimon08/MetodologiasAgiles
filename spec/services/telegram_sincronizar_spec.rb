require "rails_helper"

RSpec.describe TelegramSincronizar do
  let(:ok) { Net::HTTPOK.new("1.1", "200", "OK") }

  def respuesta(actualizaciones)
    instance_double(Net::HTTPOK, body: { ok: true, result: actualizaciones }.to_json).tap do |r|
      allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    end
  end

  def contacto(telefono, user_id: 7, chat_id: 7)
    {
      "update_id" => 10,
      "message" => {
        "chat" => { "id" => chat_id, "type" => "private" }, "from" => { "id" => user_id },
        "contact" => { "phone_number" => telefono, "user_id" => user_id }
      }
    }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return("tok")
    allow(TelegramEnviar).to receive(:call).and_return(true)
    allow(TelegramApi).to receive(:post).and_return(ok)
  end

  it "vincula la aseguradora cuyo teléfono coincide con el contacto compartido" do
    aseguradora = create(:aseguradora, telefono: "1155551234")
    allow(TelegramApi).to receive(:post).with("getUpdates", hash_including("timeout")).and_return(
      respuesta([ contacto("+5491155551234") ])
    )

    expect(described_class.call).to eq(1)

    expect(aseguradora.reload.telegram_chat_id).to eq("7")
    expect(TelegramEnviar).to have_received(:call).with(
      texto: /quedaste vinculado como contacto de #{aseguradora.nombre}/, chat_ids: [ "7" ], reply_markup: anything
    )
  end

  it "confirma las actualizaciones procesadas" do
    allow(TelegramApi).to receive(:post).with("getUpdates", hash_including("timeout")).and_return(
      respuesta([ contacto("+5491100000000") ])
    )

    described_class.call

    expect(TelegramApi).to have_received(:post).with("getUpdates", "offset" => 11, "timeout" => 0)
  end

  it "vincula también al cliente cuyo teléfono coincide con el contacto compartido" do
    cliente = create(:cliente, telefono: "1166667777")
    allow(TelegramApi).to receive(:post).with("getUpdates", hash_including("timeout")).and_return(
      respuesta([ contacto("+5491166667777") ])
    )

    described_class.call

    expect(cliente.reload.telegram_chat_id).to eq("7")
  end

  it "avisa si el número no pertenece a ninguna aseguradora" do
    aseguradora = create(:aseguradora, telefono: "1155551234")
    allow(TelegramApi).to receive(:post).with("getUpdates", hash_including("timeout")).and_return(
      respuesta([ contacto("+5491199998888") ])
    )

    described_class.call

    expect(aseguradora.reload.telegram_chat_id).to be_nil
    expect(TelegramEnviar).to have_received(:call).with(
      texto: /No encontramos ese número/, chat_ids: [ "7" ], reply_markup: anything
    )
  end

  it "rechaza un contacto que no es del propio usuario" do
    aseguradora = create(:aseguradora, telefono: "1155551234")
    actualizacion = contacto("+5491155551234")
    actualizacion["message"]["contact"]["user_id"] = 99
    allow(TelegramApi).to receive(:post).with("getUpdates", hash_including("timeout")).and_return(respuesta([ actualizacion ]))

    described_class.call

    expect(aseguradora.reload.telegram_chat_id).to be_nil
    expect(TelegramEnviar).to have_received(:call).with(texto: /tu propio contacto/, chat_ids: [ "7" ])
  end

  it "pide el contacto cuando escriben cualquier otra cosa" do
    texto = { "update_id" => 3, "message" => { "chat" => { "id" => 7, "type" => "private" }, "text" => "hola" } }
    allow(TelegramApi).to receive(:post).with("getUpdates", hash_including("timeout")).and_return(respuesta([ texto ]))

    described_class.call

    expect(TelegramEnviar).to have_received(:call).with(
      texto: /compartí tu contacto/, chat_ids: [ "7" ], reply_markup: described_class::BOTON_CONTACTO
    )
  end

  it "no hace nada si no hay token" do
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return(nil)

    expect(described_class.call).to eq(0)
    expect(TelegramApi).not_to have_received(:post)
  end
end
