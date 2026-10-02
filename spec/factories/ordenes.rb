FactoryBot.define do
  factory :orden do
    vehiculo
    cliente { vehiculo.cliente }
    sequence(:motivo) { |n| "Motivo de ingreso #{n}" }
    estado { :abierta }

    trait :cerrada do
      estado { :cerrada }
    end
  end
end
