FactoryBot.define do
  factory :caso do
    aseguradora
    asegurado factory: :cliente
    vehiculo { association :vehiculo, cliente: asegurado }
    sequence(:numero_siniestro) { |n| "SIN-#{n}" }
    descripcion { nil }
  end
end
