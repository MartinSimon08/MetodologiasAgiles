class EnvioPresupuesto < ApplicationRecord
  self.table_name = "envios_presupuesto"

  MEDIOS = %w[email whatsapp].freeze

  belongs_to :orden
  belongs_to :aseguradora
  belongs_to :enviado_por, class_name: "Usuario"

  validates :medio, inclusion: { in: MEDIOS }
  validates :destinatario, presence: true
  validates :enviado_en, presence: true
end
