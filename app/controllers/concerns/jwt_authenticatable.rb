require "jwt_validator"

module JwtAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_request!
    token = extract_bearer_token
    @current_payload = JwtValidator.verify(token)
  rescue JWT::ExpiredSignature
    render json: { error: "Token has expired" }, status: :unauthorized
  rescue JWT::DecodeError => e
    render json: { error: e.message }, status: :unauthorized
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    raise JWT::DecodeError, "Missing token" unless header&.start_with?("Bearer ")

    header.split(" ", 2).last.strip
  end
end
