namespace :mail do
  desc "Manda un mail de prueba: bin/rails mail:probar destinatario=tu@mail.com"
  task probar: :environment do
    destinatario = ENV["destinatario"].presence or abort "Pasá destinatario=tu@mail.com"
    abort "Falta MAIL_REMITENTE en el .env" if EmailEnviar.remitente.nil?
    abort "Falta RESEND_API_KEY o BREVO_API_KEY en el .env" if ENV["RESEND_API_KEY"].blank? && ENV["BREVO_API_KEY"].blank?

    if EmailEnviar.call(destinatario: destinatario, asunto: "Prueba del taller", texto: "Si lo ves, el envío de mail funciona.")
      puts "Mail enviado a #{destinatario}"
    else
      abort "No se pudo enviar. Revisá las claves, el remitente verificado y el log"
    end
  end
end
