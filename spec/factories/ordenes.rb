FactoryBot.define do
  factory :orden do
    vehiculo
    cliente { vehiculo.cliente }
    sequence(:motivo) { |n| "Motivo de ingreso #{n}" }
    estado { :abierta }

    trait :cerrada do
      estado { :cerrada }
      cerrada_en { Time.current }
      cerrada_por { association :usuario, :administrador }
      total_cerrado { 0 }
    end

    trait :cancelada do
      estado { :cancelada }
      cancelada_en { Time.current }
    end
  end
end
