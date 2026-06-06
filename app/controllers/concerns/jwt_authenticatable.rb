require "authaction/rails"

module JwtAuthenticatable
  extend ActiveSupport::Concern
  include AuthAction::Rails::JwtAuthenticatable
end
