class OauthCodigo < ApplicationRecord
  TTL = 5.minutes

  belongs_to :usuario

  validates :digesto, :client_id, :redirect_uri, :code_challenge, :recurso, :scope, :expira_en, presence: true
end
