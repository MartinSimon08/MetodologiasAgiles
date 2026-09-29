class UsuariosController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    usuarios, meta = paginar(Usuario.order(:nombre, :id))
    tareas_en_curso = Tarea.en_curso.where(mecanico_id: usuarios.map(&:id)).group(:mecanico_id).count
    render json: {
      usuarios: usuarios.map { |usuario| serialize(usuario, tareas_en_curso: tareas_en_curso.fetch(usuario.id, 0)) },
      meta: meta
    }
  end

  def create
    usuario = UsuarioCrear.call(**usuario_params.to_h.symbolize_keys)
    render json: serialize(usuario), status: :created
  end

  def resetear_password
    usuario = Usuario.find(params[:id])
    UsuarioResetearPassword.call(usuario: usuario, password: params.require(:password))
    head :no_content
  end

  def desactivar
    resultado = UsuarioDesactivar.call(usuario: Usuario.find(params[:id]))
    render json: serialize(resultado.usuario).merge(
      tareas_liberadas: resultado.tareas_liberadas.map { |tarea| tarea.as_json(only: %i[id orden_id descripcion]) }
    )
  end

  private

  def usuario_params
    params.require(:usuario).permit(:nombre, :email, :rol, :password).with_defaults(nombre: nil, email: nil, rol: nil, password: nil)
  end

  def serialize(usuario, tareas_en_curso: 0)
    usuario.as_json(only: %i[id nombre email rol activo created_at]).merge("tareas_en_curso" => tareas_en_curso)
  end
end
