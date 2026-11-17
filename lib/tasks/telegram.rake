require "net/http"
require "json"

namespace :telegram do
  desc "Lista los chats que le escribieron al bot para obtener el TELEGRAM_CHAT_ID"
  task chat_id: :environment do
    token = ENV["TELEGRAM_BOT_TOKEN"].presence or abort "Falta TELEGRAM_BOT_TOKEN en el .env"

    respuesta = Net::HTTP.get_response(URI("#{TelegramApi::API}/bot#{token}/getUpdates"))
    abort "Telegram respondió #{respuesta.code}: #{respuesta.body}" unless respuesta.is_a?(Net::HTTPSuccess)

    chats = JSON.parse(respuesta.body).fetch("result").filter_map { |u| u.dig("message", "chat") }.uniq { |c| c["id"] }
    abort "No hay mensajes. Escribile algo al bot desde Telegram y volvé a correr la tarea" if chats.empty?

    chats.each { |chat| puts "#{chat['id']}  #{chat['title'] || [ chat['first_name'], chat['last_name'] ].compact.join(' ')}" }
  end

  desc "Manda un mensaje de prueba al chat configurado"
  task probar: :environment do
    abort "Falta TELEGRAM_BOT_TOKEN o TELEGRAM_CHAT_ID en el .env" unless TelegramEnviar.configurado?

    if TelegramEnviar.call(texto: "Prueba del bot del taller")
      puts "Mensaje enviado"
    else
      abort "No se pudo enviar. Revisá el token, el chat id y el log"
    end
  end

  desc "Procesa una vez los mensajes pendientes del bot y vincula aseguradoras"
  task sincronizar: :environment do
    puts "Mensajes procesados: #{TelegramSincronizar.call}"
  end

  desc "Escucha al bot de forma continua para vincular aseguradoras"
  task escuchar: :environment do
    abort "Falta TELEGRAM_BOT_TOKEN en el .env" if TelegramApi.token.nil?

    $stdout.sync = true
    puts "Escuchando al bot de Telegram"
    loop { TelegramSincronizar.call(timeout: 25) }
  end
end
