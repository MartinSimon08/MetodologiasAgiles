FactoryBot.define do
  factory :envio_presupuesto do
    orden
    aseguradora
    enviado_por factory: :usuario
    medio { "email" }
    destinatario { "siniestros@aseguradora.test" }
    enviado_en { Time.current }
  end
end
