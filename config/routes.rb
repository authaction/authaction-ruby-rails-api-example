Rails.application.routes.draw do
  get "/public",    to: "messages#public_message"
  get "/protected", to: "messages#protected_message"
end
