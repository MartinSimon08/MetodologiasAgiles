FactoryBot.define do
  factory :vehiculo do
    cliente
    sequence(:patente) { |n| format("AA%03dBB", n % 1000) }
    marca { "Ford" }
    modelo { "Fiesta" }
    anio { 2015 }
    kilometraje { 85_000 }
  end
end
