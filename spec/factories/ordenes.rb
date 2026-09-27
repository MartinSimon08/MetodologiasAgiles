FactoryBot.define do
  factory :orden do
    cliente
    sequence(:vehiculo) { |n| "Vehículo #{n}" }
    estado { :abierta }

    trait :cerrada do
      estado { :cerrada }
    end
  end
end
