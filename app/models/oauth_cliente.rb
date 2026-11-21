class OauthCliente < ApplicationRecord
  ORIGENES = %w[registro metadata].freeze

  validates :client_id, :nombre, :origen, presence: true
  validates :origen, inclusion: { in: ORIGENES }
  validates :redirect_uris, presence: true
end
