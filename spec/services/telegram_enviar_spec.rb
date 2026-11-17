require "rails_helper"

RSpec.describe TelegramEnviar do
  it "no envía nada si el bot no está configurado" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return(nil)
    allow(Net::HTTP).to receive(:post_form)

    expect(described_class.call(texto: "hola")).to be(false)
    expect(Net::HTTP).not_to have_received(:post_form)
  end

  it "envía el texto al chat configurado" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return("tok")
    allow(ENV).to receive(:[]).with("TELEGRAM_CHAT_ID").and_return("42")
    allow(Net::HTTP).to receive(:post_form).and_return(Net::HTTPOK.new("1.1", "200", "OK"))

    expect(described_class.call(texto: "hola")).to be(true)
    expect(Net::HTTP).to have_received(:post_form).with(
      URI("https://api.telegram.org/bottok/sendMessage"), "chat_id" => "42", "text" => "hola"
    )
  end

  it "envía el texto a cada chat configurado" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return("tok")
    allow(ENV).to receive(:[]).with("TELEGRAM_CHAT_ID").and_return("42, 77")
    allow(Net::HTTP).to receive(:post_form).and_return(Net::HTTPOK.new("1.1", "200", "OK"))

    expect(described_class.call(texto: "hola")).to be(true)
    expect(Net::HTTP).to have_received(:post_form).twice
  end

  it "devuelve false si la API responde con error" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return("tok")
    allow(ENV).to receive(:[]).with("TELEGRAM_CHAT_ID").and_return("42")
    allow(Net::HTTP).to receive(:post_form).and_return(instance_double(Net::HTTPBadRequest, code: "400", body: "bad"))

    expect(described_class.call(texto: "hola")).to be(false)
  end
end
