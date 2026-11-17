class TurneraController < ApplicationController
  before_action :require_administrador!

  def show
    resultado = TurneraArmar.call(fecha: params[:fecha], periodo: params[:periodo])
    return render json: { errors: resultado.errors }, status: :unprocessable_content if resultado.invalid?

    render json: {
      periodo: resultado.periodo,
      desde: resultado.desde,
      hasta: resultado.hasta,
      cupo_diario: resultado.cupo_diario,
      dias: resultado.dias.map { |dia| serialize_dia(dia) }
    }
  end

  private

  def serialize_dia(dia)
    {
      fecha: dia.fecha,
      ingresos: dia.ingresos,
      supera_cupo: dia.supera_cupo?,
      turnos: dia.turnos.map { |turno| serialize_turno(turno) }
    }
  end

  def serialize_turno(turno)
    caso = turno.caso
    {
      caso_id: caso.id,
      numero_siniestro: caso.numero_siniestro,
      estado: turno.estado,
      orden_id: caso.orden_id,
      aseguradora: caso.aseguradora.as_json(only: %i[id nombre]),
      asegurado: caso.asegurado.as_json(only: %i[id nombre telefono]),
      vehiculo: caso.vehiculo.as_json(only: %i[id patente marca modelo])
    }
  end
end
