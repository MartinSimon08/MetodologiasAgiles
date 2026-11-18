require "rails_helper"

RSpec.describe NotificacionAsegurado do
  it "es válida con los datos de la factory" do
    expect(build(:notificacion_asegurado)).to be_valid
  end

  it "exige contenido" do
    notificacion = build(:notificacion_asegurado, contenido: "")

    expect(notificacion).not_to be_valid
    expect(notificacion.errors[:contenido]).to be_present
  end

  it "exige la fecha de envío" do
    notificacion = build(:notificacion_asegurado, enviada_en: nil)

    expect(notificacion).not_to be_valid
    expect(notificacion.errors[:enviada_en]).to be_present
  end

  it "rechaza un medio desconocido" do
    expect(build(:notificacion_asegurado, medio: "carta_documento")).not_to be_valid
  end

  it "acepta telegram o sms como medio" do
    expect(build(:notificacion_asegurado, medio: :telegram)).to be_valid
    expect(build(:notificacion_asegurado, medio: :email)).to be_valid
    expect(build(:notificacion_asegurado, medio: :sms)).to be_valid
  end
end
