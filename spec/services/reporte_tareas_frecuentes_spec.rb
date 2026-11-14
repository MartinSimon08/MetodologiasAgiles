require "rails_helper"

RSpec.describe ReporteTareasFrecuentes do
  def terminada(descripcion)
    create(:tarea, :terminada, descripcion: descripcion)
  end

  it "agrupa las tareas terminadas por descripción y cuenta cuántas veces se hizo cada una" do
    terminada("Cambio de aceite")
    terminada("Cambio de aceite")
    terminada("Cambio de aceite")
    terminada("Alineación")
    terminada("Alineación")
    terminada("Rotación de neumáticos")

    reporte = described_class.call

    expect(reporte.map { |fila| [ fila.descripcion, fila.cantidad ] }).to eq([
      [ "Cambio de aceite", 3 ],
      [ "Alineación", 2 ],
      [ "Rotación de neumáticos", 1 ]
    ])
  end

  it "agrupa sin distinguir mayúsculas ni acentos, y sin los espacios de más al guardar" do
    terminada("Cambio de aceite")
    terminada("cambio de aceite")
    terminada("  Cambio   de   aceite ")
    terminada("Alineacion")
    terminada("Alineación")

    reporte = described_class.call

    expect(reporte).to contain_exactly(
      have_attributes(descripcion: "Cambio de aceite", cantidad: 3),
      have_attributes(cantidad: 2).and(have_attributes(descripcion: a_string_matching(/\AAlineaci[oó]n\z/)))
    )
  end

  it "guarda la descripción sin espacios de más" do
    expect(terminada("  Cambio   de   aceite ").descripcion).to eq("Cambio de aceite")
  end

  it "no cuenta las tareas pendientes, en curso ni canceladas" do
    terminada("Cambio de aceite")
    create(:tarea, descripcion: "Cambio de aceite")
    create(:tarea, :en_curso, descripcion: "Cambio de aceite")
    create(:tarea, descripcion: "Cambio de aceite", estado: :cancelada)

    reporte = described_class.call

    expect(reporte).to contain_exactly(have_attributes(descripcion: "Cambio de aceite", cantidad: 1))
  end

  it "cuenta una tarea terminada aunque haya sido rechazada" do
    terminada("Cambio de aceite").update!(aprobacion: :rechazada)

    reporte = described_class.call

    expect(reporte).to contain_exactly(have_attributes(descripcion: "Cambio de aceite", cantidad: 1))
  end

  it "devuelve una lista vacía cuando no hay tareas terminadas" do
    create(:tarea, descripcion: "Cambio de aceite")

    expect(described_class.call).to eq([])
  end
end
