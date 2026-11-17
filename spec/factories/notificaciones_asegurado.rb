FactoryBot.define do
  factory :notificacion_asegurado do
    caso
    # medio { :whatsapp }
    medio { :telegram }
    contenido { "Tu vehículo ya está listo para retirar." }
    enviada_en { Time.current }
  end
end
