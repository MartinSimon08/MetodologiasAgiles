FactoryBot.define do
  factory :aseguradora do
    sequence(:nombre) { |n| "Aseguradora #{n}" }
    telefono { nil }
    email { nil }
    activa { true }

    trait :con_contacto do
      sequence(:telefono) { |n| format("11%08d", n) }
      sequence(:email) { |n| "siniestros#{n}@aseguradora.test" }
    end

    trait :con_telegram do
      telegram_chat_id { "555000111" }
    end

    trait :desactivada do
      activa { false }
    end
  end
end
