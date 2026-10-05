require "rails_helper"

RSpec.describe "Autorización por rol", type: :request do
  accesos = {
    "POST /sesion" => :publico,
    "GET /sesion" => :ambos,
    "GET /configuracion_taller" => :administrador,
    "PATCH /configuracion_taller" => :administrador,
    "PUT /configuracion_taller" => :administrador,
    "GET /usuarios" => :administrador,
    "POST /usuarios" => :administrador,
    "PATCH /usuarios/:id/resetear_password" => :administrador,
    "PATCH /usuarios/:id/desactivar" => :administrador,
    "GET /clientes" => :administrador,
    "POST /clientes" => :administrador,
    "GET /vehiculos" => :administrador,
    "POST /vehiculos" => :administrador,
    "GET /vehiculos/verificar_patente" => :administrador,
    "PATCH /vehiculos/:id/cambiar_duenio" => :administrador,
    "GET /repuestos_catalogo" => :administrador,
    "POST /repuestos_catalogo" => :administrador,
    "PATCH /repuestos_catalogo/:id" => :administrador,
    "PUT /repuestos_catalogo/:id" => :administrador,
    "DELETE /repuestos_catalogo/:id" => :administrador,
    "GET /tareas_frecuentes" => :administrador,
    "POST /tareas_frecuentes" => :administrador,
    "GET /tareas_mecanico" => :mecanico,
    "GET /ordenes" => :ambos,
    "POST /ordenes" => :administrador,
    "GET /ordenes/:id" => :ambos,
    "GET /ordenes/:orden_id/repuestos" => :administrador,
    "POST /ordenes/:orden_id/repuestos" => :administrador,
    "GET /ordenes/:orden_id/tareas" => :ambos,
    "POST /ordenes/:orden_id/tareas" => :administrador,
    "PATCH /tareas/:id/tomar" => :mecanico,
    "PATCH /tareas/:id/completar" => :mecanico,
    "PATCH /tareas/:id/liberar" => :mecanico
  }
  roles_permitidos = {
    administrador: %i[administrador],
    mecanico: %i[mecanico],
    ambos: %i[administrador mecanico]
  }
  nombres = { administrador: "administrador", mecanico: "mecánico" }

  let(:administrador) { create(:usuario, :administrador) }
  let(:mecanico) { create(:usuario) }

  def llamar(ruta, usuario = nil)
    verbo, path = ruta.split
    process(verbo.downcase.to_sym, path.gsub(/:\w+/, "0"), headers: usuario ? auth_headers(usuario) : {})
  end

  it "declara quién puede acceder a cada ruta de la API" do
    rutas = Rails.application.routes.routes.filter_map do |ruta|
      controlador = ruta.defaults[:controller]
      next if controlador.blank? || controlador.start_with?("rails/", "active_storage/", "action_mailbox/")

      "#{ruta.verb} #{ruta.path.spec.to_s.delete_suffix('(.:format)')}"
    end

    expect(accesos.keys).to match_array(rutas)
  end

  accesos.each do |ruta, acceso|
    next if acceso == :publico

    describe ruta do
      it "exige autenticación" do
        llamar(ruta)

        expect(response).to have_http_status(:unauthorized)
      end

      nombres.each do |rol, nombre|
        if roles_permitidos.fetch(acceso).include?(rol)
          it "deja pasar al #{nombre}" do
            llamar(ruta, send(rol))

            expect(response).not_to have_http_status(:unauthorized)
            expect(response).not_to have_http_status(:forbidden)
          end
        else
          it "responde 403 al #{nombre} sin devolver datos" do
            llamar(ruta, send(rol))

            expect(response).to have_http_status(:forbidden)
            expect(response.body).to be_empty
          end
        end
      end
    end
  end
end
