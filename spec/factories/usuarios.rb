FactoryBot.define do
  factory :usuario do
    sequence(:nombre) { |n| "Usuario #{n}" }
    sequence(:email) { |n| "usuario#{n}@taller.test" }
    rol { :mecanico }
    password { PasswordsDePrueba::VALIDA }

    trait :administrador do
      rol { :administrador }
    end
  end
end
