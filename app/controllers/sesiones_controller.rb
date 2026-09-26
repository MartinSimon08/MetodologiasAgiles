class SesionesController < ApplicationController
  allow_unauthenticated_access only: :create

  def show
    render json: current_usuario.as_json(only: %i[id nombre email rol])
  end

  def create
    token = UsuarioAutenticar.call(email: params[:email], password: params[:password])

    if token
      render json: { token: token }, status: :created
    else
      render json: { error: "Email o contraseña incorrectos" }, status: :unauthorized
    end
  end
end
