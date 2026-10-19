module OrdenesHelpers
  def marcar_cerrada(orden)
    orden.update_columns(estado: "cerrada", cerrada_en: Time.current,
                         cerrada_por_id: create(:usuario, :administrador).id, total_cerrado: orden.total)
    orden
  end
end

RSpec.configure do |config|
  config.include OrdenesHelpers
end
