require "rails_helper"

RSpec.describe "GET /llms.txt", type: :request do
  it "sirve el archivo de la raíz del repositorio sin autenticación" do
    get "/llms.txt"

    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Type"]).to eq("text/plain; charset=utf-8")
    expect(response.headers["Cache-Control"]).to include("public").and include("max-age=600")
    expect(response.body.dup.force_encoding(Encoding::UTF_8)).to eq(Rails.root.join("llms.txt").read)
  end
end
