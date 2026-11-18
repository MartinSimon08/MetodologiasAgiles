class NotificacionAsegurado < ApplicationRecord
  belongs_to :caso

  # enum :medio, { whatsapp: "whatsapp", sms: "sms" }, validate: true
  enum :medio, { telegram: "telegram", sms: "sms" }, validate: true

  validates :contenido, presence: true
  validates :enviada_en, presence: true
end
