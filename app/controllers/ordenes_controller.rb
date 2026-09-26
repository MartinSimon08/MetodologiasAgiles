class OrdenesController < ApplicationController
  include Paginable

  def index
    ordenes, meta = paginar(Orden.order(created_at: :desc, id: :desc))
    render json: { ordenes: ordenes.map { |orden| serialize(orden) }, meta: meta }
  end

  def show
    render json: serialize(Orden.find(params[:id]))
  end

  private

  def serialize(orden)
    orden.as_json(only: %i[id cliente vehiculo estado created_at])
  end
end
