FactoryBot.define do
  factory :tarea_frecuente do
    sequence(:descripcion) { |n| "Cambio de aceite #{n}" }
    precio_sugerido { 15_000 }
  end
end
