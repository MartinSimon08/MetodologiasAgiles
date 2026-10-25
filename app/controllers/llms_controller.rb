class LlmsController < ApplicationController
  allow_unauthenticated_access

  def show
    response.set_header("Cache-Control", "public, max-age=600")
    send_file Rails.root.join("llms.txt"), type: "text/plain; charset=utf-8", disposition: "inline"
  end
end
