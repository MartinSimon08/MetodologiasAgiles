class ClientesController < ApplicationController
  include Paginable

  before_action :require_administrador!

  def index
    clientes, meta = paginar(Cliente.order(:nombre, :id))
    render json: { clientes: clientes.map { |cliente| serialize(cliente) }, meta: meta }
  end

  def create
    cliente = ClienteRegistrar.call(**cliente_params.to_h.symbolize_keys)
    render json: serialize(cliente), status: :created
  end

  private

  def cliente_params
    params.require(:cliente).permit(:nombre, :telefono, :email).with_defaults(nombre: nil, telefono: nil)
  end

  def serialize(cliente)
    cliente.as_json(only: %i[id nombre telefono email created_at])
  end
end
