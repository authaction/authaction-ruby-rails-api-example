require "jwt"
require "net/http"
require "json"

class JwtValidator
  DOMAIN   = ENV["AUTHACTION_DOMAIN"]
  AUDIENCE = ENV["AUTHACTION_AUDIENCE"]
  ISSUER   = "https://#{DOMAIN}"
  JWKS_URI = "https://#{DOMAIN}/.well-known/jwks.json"

  CACHE_KEY = "authaction_jwks"
  CACHE_TTL = 1.hour

  def self.verify(token)
    payload, _header = JWT.decode(
      token, nil, true,
      algorithms:  ["RS256"],
      iss:         ISSUER,
      verify_iss:  true,
      aud:         AUDIENCE,
      verify_aud:  true,
      jwks:        jwks_loader
    )
    payload
  end

  def self.jwks_loader
    # The jwt gem calls this lambda with kid_not_found: true when the signing
    # key is not in the cached set, allowing a single cache-bust on key rotation.
    lambda do |options|
      Rails.cache.delete(CACHE_KEY) if options[:kid_not_found]
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
        response = Net::HTTP.get(URI(JWKS_URI))
        JSON.parse(response, symbolize_names: true)
      end
    end
  end
end
