FactoryBot.define do
  factory :tarea_nota do
    tarea
    sequence(:contenido) { |n| "Nota #{n}" }
    registrado_por { create(:usuario) }
  end
end
