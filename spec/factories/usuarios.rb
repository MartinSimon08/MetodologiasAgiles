FactoryBot.define do
  factory :usuario do
    sequence(:nombre) { |n| "Usuario #{n}" }
    sequence(:email) { |n| "usuario#{n}@taller.test" }
    rol { :mecanico }
    password { "secreto123" }

    trait :administrador do
      rol { :administrador }
    end
  end
end
