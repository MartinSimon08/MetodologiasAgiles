FactoryBot.define do
  factory :orden do
    sequence(:cliente) { |n| "Cliente #{n}" }
    sequence(:vehiculo) { |n| "Vehículo #{n}" }
    estado { :abierta }

    trait :cerrada do
      estado { :cerrada }
    end
  end
end
