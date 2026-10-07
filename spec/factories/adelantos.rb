FactoryBot.define do
  factory :adelanto do
    orden
    importe { "2500.00" }
    registrado_en { Time.current }
    registrado_por { create(:usuario, :administrador) }
  end
end
