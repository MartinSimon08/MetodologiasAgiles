class RecepcionChannel < ApplicationCable::Channel
  STREAM = "recepcion_avisos".freeze

  def subscribed
    return reject unless current_usuario.administrador?

    stream_from STREAM
  end
end
