require "rails_helper"

RSpec.describe EnrutarOauth do
  let(:frontend) { ->(env) { [ 200, {}, [ "front #{env['PATH_INFO']}" ] ] } }
  let(:api) { ->(env) { [ 200, {}, [ "api #{env['PATH_INFO']}" ] ] } }
  let(:app) { described_class.new(frontend, api) }

  it "delega el descubrimiento OAuth a la API" do
    estado, _, cuerpo = app.call(Rack::PATH_INFO => "/.well-known/oauth-authorization-server/api")

    expect(estado).to eq(200)
    expect(cuerpo).to eq([ "api /.well-known/oauth-authorization-server/api" ])
  end

  it "deja el resto de las rutas en el frontend" do
    estado, _, cuerpo = app.call(Rack::PATH_INFO => "/ordenes")

    expect(estado).to eq(200)
    expect(cuerpo).to eq([ "front /ordenes" ])
  end
end
