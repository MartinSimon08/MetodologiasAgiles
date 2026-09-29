module AuthHelpers
  def auth_headers(usuario)
    { "Authorization" => "Bearer #{JsonWebToken.para(usuario)}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
