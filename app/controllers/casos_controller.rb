class CasosController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    casos = Caso.includes(:aseguradora, :asegurado, :vehiculo).order(created_at: :desc, id: :desc)
    if params[:buscar].present?
      termino = "%#{ActiveRecord::Base.sanitize_sql_like(params[:buscar].to_s.squish)}%"
      casos = casos.joins(:aseguradora, :asegurado, :vehiculo)
                   .where("casos.numero_siniestro ILIKE :t OR vehiculos.patente ILIKE :t OR clientes.nombre ILIKE :t " \
                          "OR aseguradoras.nombre ILIKE :t", t: termino)
    end
    pagina, meta = paginar(casos)
    render json: { casos: pagina.map { |caso| serialize(caso) }, meta: meta }
  end

  def create
    caso = CasoAbrir.call(**caso_params.to_h.symbolize_keys)
    render json: serialize(caso), status: :created
  end

  private

  def caso_params
    params.require(:caso).permit(:aseguradora_id, :asegurado_id, :vehiculo_id, :numero_siniestro, :descripcion)
          .with_defaults(aseguradora_id: nil, asegurado_id: nil, vehiculo_id: nil, numero_siniestro: nil)
  end

  def serialize(caso)
    caso.as_json(only: %i[id numero_siniestro descripcion fecha_turno orden_id created_at])
        .merge(
          aseguradora: caso.aseguradora.as_json(only: %i[id nombre]),
          asegurado: caso.asegurado.as_json(only: %i[id nombre telefono]),
          vehiculo: caso.vehiculo.as_json(only: %i[id patente marca modelo])
        )
  end
end
