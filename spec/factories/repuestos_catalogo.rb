FactoryBot.define do
  factory :repuesto_catalogo do
    sequence(:nombre) { |n| "Filtro #{n}" }
    precio { "100.50" }
  end
end
