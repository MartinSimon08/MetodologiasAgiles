module AuthHelpers
  def auth_headers(usuario)
    { "Authorization" => "Bearer #{JsonWebToken.encode({ usuario_id: usuario.id, rol: usuario.rol })}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
