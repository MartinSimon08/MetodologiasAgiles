FactoryBot.define do
  factory :cliente do
    sequence(:nombre) { |n| "Cliente #{n}" }
    sequence(:telefono) { |n| format("11%08d", n) }
    email { nil }

    trait :con_email do
      sequence(:email) { |n| "cliente#{n}@correo.test" }
    end
  end
end
