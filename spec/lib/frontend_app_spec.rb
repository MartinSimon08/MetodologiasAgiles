require "rails_helper"

RSpec.describe FrontendApp do
  let(:root) { Dir.mktmpdir }
  let(:request) { Rack::MockRequest.new(described_class.new(root)) }

  before do
    File.write(File.join(root, "index.html"), "<div id=\"root\"></div>")
    File.write(File.join(root, "home.md"), "# Gestión de Taller\n\nTexto público.\n")
    File.write(File.join(root, "about.html"), "<h1>Acerca de</h1>")
    File.write(File.join(root, "about.md"), "# Acerca de\n")
    FileUtils.mkdir_p(File.join(root, "assets"))
    File.write(File.join(root, "assets", "app-abc123.js"), "console.log(1)")
    FileUtils.mkdir_p(File.join(root, ".well-known"))
    File.write(File.join(root, ".well-known", "api-catalog"), %({"linkset":[]}))
  end

  after { FileUtils.remove_entry(root) }

  it "sirve index.html en la raíz sin cache" do
    respuesta = request.get("/")

    expect(respuesta.status).to eq(200)
    expect(respuesta.body).to include("root")
    expect(respuesta.headers["content-type"]).to include("text/html")
    expect(respuesta.headers["cache-control"]).to eq("no-cache")
    expect(respuesta.headers["vary"]).to eq("Accept")
  end

  it "devuelve index.html en las rutas del frontend" do
    respuesta = request.get("/ordenes/42")

    expect(respuesta.status).to eq(200)
    expect(respuesta.body).to include("root")
  end

  it "sirve la consulta de casos por aseguradora" do
    respuesta = request.get("/casos/aseguradora")

    expect(respuesta.status).to eq(200)
    expect(respuesta.body).to include("root")
  end

  it "ignora la barra final de una ruta del frontend" do
    respuesta = request.get("/ordenes/")

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

  it "responde 404 en una ruta que no es del frontend" do
    respuesta = request.get("/no-existe")

    expect(respuesta.status).to eq(404)
    expect(respuesta.headers["content-type"]).to include("text/html")
    expect(respuesta.body).to include("No encontrado")
    expect(respuesta.body).to include("llms.txt")
    expect(respuesta.body).not_to include('id="root"')
  end

  it "negocia Markdown en la home" do
    respuesta = request.get("/", "HTTP_ACCEPT" => "text/markdown")

    expect(respuesta.status).to eq(200)
    expect(respuesta.headers["content-type"]).to eq("text/markdown; charset=utf-8")
    expect(respuesta.headers["vary"]).to eq("Accept")
    expect(respuesta.body).to include("Gestión de Taller")
  end

  it "mantiene HTML cuando el cliente lo prefiere" do
    accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    respuesta = request.get("/", "HTTP_ACCEPT" => accept)

    expect(respuesta.status).to eq(200)
    expect(respuesta.headers["content-type"]).to include("text/html")
    expect(respuesta.body).to include("root")
  end

  it "prefiere Markdown si su calidad es mayor" do
    respuesta = request.get("/", "HTTP_ACCEPT" => "text/markdown, text/html;q=0.9")

    expect(respuesta.status).to eq(200)
    expect(respuesta.headers["content-type"]).to include("text/markdown")
  end

  it "responde 406 si el cliente rechaza HTML y Markdown" do
    respuesta = request.get("/", "HTTP_ACCEPT" => "application/json")

    expect(respuesta.status).to eq(406)
    expect(respuesta.headers["vary"]).to eq("Accept")
  end

  it "describe la pantalla de la app en Markdown" do
    respuesta = request.get("/login", "HTTP_ACCEPT" => "text/markdown")

    expect(respuesta.status).to eq(200)
    expect(respuesta.body).to include("pide sesión")
    expect(respuesta.body).to include("/llms.txt")
  end

  it "sirve las páginas públicas en HTML y en Markdown" do
    html = request.get("/about")
    markdown = request.get("/about", "HTTP_ACCEPT" => "text/markdown")

    expect(html.status).to eq(200)
    expect(html.body).to include("Acerca de")
    expect(html.headers["vary"]).to eq("Accept")
    expect(markdown.status).to eq(200)
    expect(markdown.headers["content-type"]).to include("text/markdown")
    expect(markdown.body).to include("Acerca de")
  end

  it "responde 404 en Markdown con un enlace de salida" do
    respuesta = request.get("/no-existe", "HTTP_ACCEPT" => "text/markdown")

    expect(respuesta.status).to eq(404)
    expect(respuesta.headers["content-type"]).to include("text/markdown")
    expect(respuesta.body).to include("/llms.txt")
    expect(respuesta.body).to include("/no-existe")
  end

  it "sirve el catálogo de la API como linkset" do
    respuesta = request.get("/.well-known/api-catalog")

    expect(respuesta.status).to eq(200)
    expect(respuesta.headers["content-type"]).to eq(
      'application/linkset+json;profile="https://www.rfc-editor.org/info/rfc9727"'
    )
    expect(JSON.parse(respuesta.body)).to eq("linkset" => [])
  end

  it "no vuelca el shell en una ruta inexistente pedida como JSON" do
    respuesta = request.get("/no-existe", "HTTP_ACCEPT" => "application/json")

    expect(respuesta.status).to eq(406)
  end
end
