# authaction-ruby-rails-api-example

A Ruby on Rails API application demonstrating API authorization using [AuthAction](https://app.authaction.com/) with JWKS-based JWT validation.

## Overview

This application shows how to configure and handle authorization using AuthAction's access tokens in a Rails API-only app. It validates JSON Web Tokens (JWT) signed with RS256 by fetching public keys dynamically from AuthAction's JWKS endpoint, with automatic key-rotation handling.

## Prerequisites

- **Ruby 3.2+** and **Bundler**
- **AuthAction credentials**: `tenantDomain` and `apiIdentifier` from your AuthAction account.

## Installation

1. **Clone the repository**:

   ```bash
   git clone git@github.com:authaction/authaction-ruby-rails-api-example.git
   cd authaction-ruby-rails-api-example
   ```

2. **Install dependencies**:

   ```bash
   bundle install
   ```

3. **Configure your AuthAction credentials**:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and replace the placeholders:

   ```env
   AUTHACTION_DOMAIN=your-authaction-tenant-domain
   AUTHACTION_AUDIENCE=your-authaction-api-identifier
   SECRET_KEY_BASE=$(rails secret)
   ```

## Usage

1. **Start the development server**:

   ```bash
   rails server
   ```

   The API will be available at `http://localhost:3000`.

2. **Obtain an access token** via client credentials:

   ```bash
   curl --request POST \
     --url https://your-authaction-tenant-domain/oauth2/m2m/token \
     --header 'content-type: application/json' \
     --data '{
       "client_id": "your-authaction-app-clientid",
       "client_secret": "your-authaction-app-client-secret",
       "audience": "your-authaction-api-identifier",
       "grant_type": "client_credentials"
     }'
   ```

3. **Call the public endpoint** (no token required):

   ```bash
   curl http://localhost:3000/public
   ```

   ```json
   { "message": "This is a public message!" }
   ```

4. **Call the protected endpoint** with the access token:

   ```bash
   curl --request GET \
     --url http://localhost:3000/protected \
     --header 'Authorization: Bearer YOUR_ACCESS_TOKEN'
   ```

   ```json
   { "message": "This is a protected message!", "sub": "client-id@clients" }
   ```

## Project Structure

```
authaction-ruby-rails-api-example/
├── app/
│   └── controllers/
│       ├── concerns/
│       │   └── jwt_authenticatable.rb   # Concern: token extraction + error handling
│       ├── application_controller.rb    # Includes JwtAuthenticatable
│       └── messages_controller.rb       # public + protected actions
├── lib/
│   └── jwt_validator.rb                 # JWKS fetching, caching, and JWT decode
├── config/
│   ├── routes.rb
│   └── initializers/
│       └── authaction.rb                # Validates required env vars on boot
├── .env.example
├── Gemfile
└── README.md
```

## Code Explanation

### `lib/jwt_validator.rb` — JWT Validation

Equivalent to `JwtStrategy` in the NestJS example.

- **`jwks_loader`** — Returns a lambda that the `jwt` gem calls to retrieve
  public keys. It caches the JWKS in `Rails.cache` for 1 hour. When the gem
  detects a `kid` mismatch it calls the lambda again with
  `kid_not_found: true`, which busts the cache and re-fetches — handling key
  rotation automatically.

- **`verify(token)`** — Decodes and validates the JWT via `JWT.decode` with:
  - Algorithm: `RS256`
  - Issuer: `https://{AUTHACTION_DOMAIN}` (`verify_iss: true`)
  - Audience: `{AUTHACTION_AUDIENCE}` (`verify_aud: true`)

  Unlike Laravel/PHP, the `jwt` gem enforces issuer and audience natively via
  decode options — no manual checking required.

### `app/controllers/concerns/jwt_authenticatable.rb` — Auth Concern

- **`authenticate_request!`** — Calls `JwtValidator.verify` and stores the
  decoded payload in `@current_payload`. Renders a 401 JSON response on any
  `JWT::DecodeError`.
- Included into `ApplicationController` so all controllers inherit it.

### `app/controllers/messages_controller.rb` — Controller

- **`GET /public`** — No `before_action`, accessible without authentication.
- **`GET /protected`** — `before_action :authenticate_request!` guards the
  action. The verified payload is available via `@current_payload`.

## Common Issues

**Invalid token errors** — Verify that `AUTHACTION_DOMAIN` and
`AUTHACTION_AUDIENCE` match the values in your AuthAction dashboard exactly.

**Public key fetching errors** — Check that your application can reach
`https://{AUTHACTION_DOMAIN}/.well-known/jwks.json`.

**Unauthorized access** — Ensure the `Authorization: Bearer <token>` header is
present and the token was issued for the correct audience.

## Contributing

Feel free to submit issues or pull requests if you encounter bugs or have suggestions for improvement!
