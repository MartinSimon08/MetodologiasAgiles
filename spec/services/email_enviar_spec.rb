require "rails_helper"

RSpec.describe EmailEnviar do
  let(:ok) { Net::HTTPOK.new("1.1", "200", "OK") }
  let(:error) { instance_double(Net::HTTPBadRequest, code: "400", body: "bad") }

  def configurar(resend: "rk", brevo: "bk", remitente: "taller@ejemplo.com")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("RESEND_API_KEY").and_return(resend)
    allow(ENV).to receive(:[]).with("BREVO_API_KEY").and_return(brevo)
    allow(ENV).to receive(:[]).with("MAIL_REMITENTE").and_return(remitente)
  end

  def enviar
    described_class.call(destinatario: "a@b.com", asunto: "Hola", texto: "Cuerpo")
  end

  it "envía por Resend y no usa Brevo si funciona" do
    configurar
    allow(Net::HTTP).to receive(:post).and_return(ok)

    expect(enviar).to be(true)
    expect(Net::HTTP).to have_received(:post).once.with(
      URI("https://api.resend.com/emails"), /"to":\["a@b.com"\]/,
      hash_including("Authorization" => "Bearer rk")
    )
  end

  it "usa Brevo si Resend falla" do
    configurar
    allow(Net::HTTP).to receive(:post).with(URI("https://api.resend.com/emails"), anything, anything).and_return(error)
    allow(Net::HTTP).to receive(:post).with(URI("https://api.brevo.com/v3/smtp/email"), anything, anything).and_return(ok)

    expect(enviar).to be(true)
    expect(Net::HTTP).to have_received(:post).with(
      URI("https://api.brevo.com/v3/smtp/email"), /"textContent":"Cuerpo"/, hash_including("api-key" => "bk")
    )
  end

  it "usa Brevo si Resend no está configurado" do
    configurar(resend: nil)
    allow(Net::HTTP).to receive(:post).and_return(ok)

    expect(enviar).to be(true)
    expect(Net::HTTP).to have_received(:post).once.with(URI("https://api.brevo.com/v3/smtp/email"), anything, anything)
  end

  it "devuelve false si fallan los dos proveedores" do
    configurar
    allow(Net::HTTP).to receive(:post).and_return(error)

    expect(enviar).to be(false)
  end

  it "devuelve false si hay un error de red" do
    configurar
    allow(Net::HTTP).to receive(:post).and_raise(SocketError)

    expect(enviar).to be(false)
  end

  it "no envía nada si no hay remitente configurado" do
    configurar(remitente: nil)
    allow(Net::HTTP).to receive(:post)

    expect(enviar).to be(false)
    expect(Net::HTTP).not_to have_received(:post)
  end
end
