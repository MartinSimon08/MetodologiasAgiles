require "rails_helper"

RSpec.describe "páginas públicas para agentes" do
  def texto_visible(html)
    sin_scripts = html.gsub(%r{<script\b.*?</script>}m, " ")
    sin_etiquetas = sin_scripts.gsub(/<[^>]+>/, " ")
    sin_etiquetas.gsub(/\s+/, " ").strip
  end

  it "deja la home legible sin JavaScript" do
    html = Rails.root.join("frontend/index.html").read

    expect(texto_visible(html).length).to be > 500
    expect(html).to include("<h1>Gestión de Taller</h1>")
    expect(html).to include('lang="es"')
    expect(html).to include('rel="canonical"')
    expect(html).to include('property="og:image"')
    expect(html).to include('property="og:type"')
    expect(html).to include('"@type": "SoftwareApplication"')
    expect(html).to include('name="is-agentic-site-type" content="app"')
  end

  %w[about contact privacy docs].each do |pagina|
    it "deja /#{pagina} con texto propio" do
      html = Rails.root.join("frontend/public/#{pagina}.html").read

      expect(texto_visible(html).length).to be > 500
      expect(html).to include("<h1>")
    end
  end

  it "describe la home también en Markdown" do
    markdown = Rails.root.join("frontend/public/home.md").read

    expect(markdown).to include("# Gestión de Taller")
    expect(markdown).to include("## Cuándo usarlo")
    expect(markdown.length).to be > 500
  end

  it "lista solo las URLs públicas en el sitemap" do
    xml = Rails.root.join("frontend/public/sitemap.xml").read
    locales = xml.scan(%r{<loc>(.*?)</loc>}).flatten

    expect(locales).to include(
      "https://204-216-155-6.sslip.io/",
      "https://204-216-155-6.sslip.io/about",
      "https://204-216-155-6.sslip.io/contact",
      "https://204-216-155-6.sslip.io/privacy",
      "https://204-216-155-6.sslip.io/docs"
    )
    expect(locales).not_to include(a_string_matching(%r{/ordenes}))
    expect(xml).to include("<lastmod>")
  end

  it "publica un catálogo de API válido" do
    catalogo = JSON.parse(Rails.root.join("frontend/public/.well-known/api-catalog").read)

    expect(catalogo.fetch("linkset")).to be_an(Array)
    expect(catalogo.fetch("linkset").first.fetch("anchor")).to eq("https://204-216-155-6.sslip.io/api")
  end

  it "dice en llms.txt cuándo usar el sistema" do
    texto = Rails.root.join("llms.txt").read

    expect(texto).to include("## Cuándo usarlo")
    expect(texto).to include("https://204-216-155-6.sslip.io/docs")
  end
end
