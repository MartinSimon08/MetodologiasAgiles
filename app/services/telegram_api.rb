require "net/http"

class TelegramApi
  API = "https://api.telegram.org".freeze

  def self.token
    ENV["TELEGRAM_BOT_TOKEN"].presence
  end

  def self.post(metodo, parametros)
    Net::HTTP.post_form(URI("#{API}/bot#{token}/#{metodo}"), parametros)
  end
end
