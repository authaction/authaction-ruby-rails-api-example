class MessagesController < ApplicationController
  before_action :authenticate_request!, only: [:protected_message]

  def public_message
    render json: { message: "This is a public message!" }
  end

  def protected_message
    render json: {
      message: "This is a protected message!",
      sub: @current_payload["sub"]
    }
  end
end
