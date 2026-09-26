class ApplicationController < ActionController::API
  include Authentication

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { errors: error.record.errors.to_hash(true) }, status: :unprocessable_content
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActionController::ParameterMissing do |error|
    render json: { errors: { error.param => [ error.message ] } }, status: :bad_request
  end
end
