class UsuariosController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    usuarios, meta = paginar(Usuario.order(:nombre, :id))
    render json: { usuarios: usuarios.map { |usuario| serialize(usuario) }, meta: meta }
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

  private

  def usuario_params
    params.require(:usuario).permit(:nombre, :email, :rol, :password).with_defaults(nombre: nil, email: nil, rol: nil, password: nil)
  end

  def serialize(usuario)
    usuario.as_json(only: %i[id nombre email rol created_at])
  end
end
