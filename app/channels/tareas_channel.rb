class TareasChannel < ApplicationCable::Channel
  STREAM = "tareas_disponibles".freeze

  def subscribed
    return reject unless current_usuario.mecanico?

    stream_from STREAM
    stream_for current_usuario
  end
end
