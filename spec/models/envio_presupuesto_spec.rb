require "rails_helper"

RSpec.describe EnvioPresupuesto do
  it "es válido con orden, aseguradora, medio, destinatario y fecha" do
    expect(build(:envio_presupuesto)).to be_valid
  end

  it "rechaza un medio desconocido" do
    envio = build(:envio_presupuesto, medio: "paloma")

    expect(envio).not_to be_valid
    expect(envio.errors[:medio]).to be_present
  end

  it "exige el destinatario" do
    expect(build(:envio_presupuesto, destinatario: nil)).not_to be_valid
  end

  it "exige la fecha de envío" do
    expect(build(:envio_presupuesto, enviado_en: nil)).not_to be_valid
  end
end
