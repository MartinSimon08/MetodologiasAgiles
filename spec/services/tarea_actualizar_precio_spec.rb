require "rails_helper"

RSpec.describe TareaActualizarPrecio do
  let(:tarea) { create(:tarea, :en_curso, precio: 15_000) }

  it "actualiza el precio de la tarea" do
    described_class.call(tarea: tarea, precio: "18000")

    expect(tarea.reload.precio).to eq(18_000)
  end

  it "permite borrar el precio cargado" do
    described_class.call(tarea: tarea, precio: nil)

    expect(tarea.reload.precio).to be_nil
  end

  it "rechaza un precio negativo" do
    expect { described_class.call(tarea: tarea, precio: "-1") }
      .to raise_error(ActiveRecord::RecordInvalid)

    expect(tarea.reload.precio).to eq(15_000)
  end
end
