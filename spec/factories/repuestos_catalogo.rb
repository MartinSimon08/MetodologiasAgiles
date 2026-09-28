FactoryBot.define do
  factory :repuesto_catalogo do
    sequence(:nombre) { |n| "Filtro #{n}" }
    ultimo_costo { "100.50" }
  end
end
