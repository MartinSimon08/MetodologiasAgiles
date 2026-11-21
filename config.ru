# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

frontend_dist = ENV["FRONTEND_DIST_PATH"]

if frontend_dist.present? && File.directory?(frontend_dist)
  api = Rails.application
  map("/api") { run api }
  map("/") { run EnrutarOauth.new(FrontendApp.new(frontend_dist), api) }
else
  run Rails.application
end

Rails.application.load_server
