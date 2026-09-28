class ConfiguracionesTallerController < ApplicationController
  before_action :require_administrador!, only: :update

  def show
    render json: serialize(ConfiguracionTaller.actual)
  end

  def update
    configuracion = ConfiguracionTallerActualizar.call(**configuracion_params.to_h.symbolize_keys)
    render json: serialize(configuracion)
  end

  private

  def configuracion_params
    params.require(:configuracion_taller).permit(:margen_repuestos).with_defaults(margen_repuestos: nil)
  end

  def serialize(configuracion)
    { margen_repuestos: configuracion.margen_repuestos.to_f }
  end
end
