require "rails_helper"

RSpec.describe FrontendApp do
  let(:root) { Dir.mktmpdir }
  let(:request) { Rack::MockRequest.new(described_class.new(root)) }

  before do
    File.write(File.join(root, "index.html"), "<div id=\"root\"></div>")
    FileUtils.mkdir_p(File.join(root, "assets"))
    File.write(File.join(root, "assets", "app-abc123.js"), "console.log(1)")
  end

  after { FileUtils.remove_entry(root) }

  it "sirve index.html en la raíz sin cache" do
    respuesta = request.get("/")

    expect(respuesta.status).to eq(200)
    expect(respuesta.body).to include("root")
    expect(respuesta.headers["cache-control"]).to eq("no-cache")
  end

  it "devuelve index.html en las rutas del frontend" do
    respuesta = request.get("/ordenes/42")

    expect(respuesta.status).to eq(200)
    expect(respuesta.body).to include("root")
  end

  it "sirve los assets con cache largo" do
    respuesta = request.get("/assets/app-abc123.js")

    expect(respuesta.status).to eq(200)
    expect(respuesta.headers["cache-control"]).to include("immutable")
  end

  it "responde 404 si falta un asset" do
    respuesta = request.get("/assets/inexistente.js")

    expect(respuesta.status).to eq(404)
    expect(respuesta.headers["cache-control"]).to eq("no-cache")
  end
end
