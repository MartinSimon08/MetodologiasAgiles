FactoryBot.define do
  factory :tarea do
    orden
    sequence(:descripcion) { |n| "Tarea #{n}" }

    trait :en_curso do
      estado { :en_curso }
      association :mecanico, factory: :usuario
      tomada_en { Time.current }
    end

    trait :terminada do
      estado { :terminada }
      association :mecanico, factory: :usuario
      tomada_en { 1.hour.ago }
      terminada_en { Time.current }
    end
  end
end
