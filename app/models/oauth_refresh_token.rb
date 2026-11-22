class OauthRefreshToken < ApplicationRecord
  TTL = 30.days

  belongs_to :usuario

  validates :digesto, :familia, :client_id, :recurso, :scope, :expira_en, presence: true
end
