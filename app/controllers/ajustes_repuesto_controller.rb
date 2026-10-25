class AjustesRepuestoController < ApplicationController
  include SerializaAjusteRepuesto

  before_action :require_administrador!
  before_action :set_orden
  before_action :set_repuesto

  def create
    ajuste = RepuestoRegistrarAjuste.call(
      repuesto: @repuesto,
      registrado_por: current_usuario,
      **ajuste_params.to_h.symbolize_keys
    )
    render json: serialize_ajuste(ajuste), status: :created
  end

  private

  def set_orden
    @orden = Orden.find(params[:orden_id])
  end

  def set_repuesto
    @repuesto = @orden.repuestos.find(params[:repuesto_id])
  end

  def ajuste_params
    params.require(:ajuste).permit(:tipo, :cantidad, :costo_unitario, :motivo)
  end
end
