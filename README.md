# authaction-ruby-rails-api-example

A Ruby on Rails API application demonstrating API authorization using [AuthAction](https://app.authaction.com/) with the `authaction-ruby-sdk`.

## Overview

This application shows how to configure and handle authorization using AuthAction's access tokens in a Rails API-only app. It validates JSON Web Tokens (JWT) using the `authaction-ruby-sdk`, which handles JWKS fetching and RS256 validation automatically.

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
│       │   └── jwt_authenticatable.rb   # Wraps AuthAction::Rails::JwtAuthenticatable
│       ├── application_controller.rb    # Includes JwtAuthenticatable
│       └── messages_controller.rb       # public + protected actions
├── config/
│   ├── routes.rb
│   └── initializers/
│       └── authaction.rb                # Validates required env vars on boot
├── .env.example
├── Gemfile
└── README.md
```

## Code Explanation

### `app/controllers/concerns/jwt_authenticatable.rb` — Auth Concern

Includes `AuthAction::Rails::JwtAuthenticatable` from `authaction/rails` (part of `authaction-ruby-sdk`). This mixin provides an `authenticate_request!` method that extracts the Bearer token, validates it using the SDK (JWKS + RS256), stores the decoded payload in `@current_payload`, and renders a 401 JSON response on any validation failure.

### `app/controllers/application_controller.rb` — Base Controller

Includes `JwtAuthenticatable` so all controllers inherit the `authenticate_request!` method.

### `app/controllers/messages_controller.rb` — Controller

- **`GET /public`** — No `before_action`, accessible without authentication.
- **`GET /protected`** — `before_action :authenticate_request!` guards the
  action. The verified payload is available via `@current_payload`.

### `config/initializers/authaction.rb` — Boot Validation

Raises at startup if `AUTHACTION_DOMAIN` or `AUTHACTION_AUDIENCE` are missing from the environment.

## Common Issues

**Invalid token errors** — Verify that `AUTHACTION_DOMAIN` and
`AUTHACTION_AUDIENCE` match the values in your AuthAction dashboard exactly.

**Public key fetching errors** — Check that your application can reach
`https://{AUTHACTION_DOMAIN}/.well-known/jwks.json`.

**Unauthorized access** — Ensure the `Authorization: Bearer <token>` header is
present and the token was issued for the correct audience.

## Contributing

Feel free to submit issues or pull requests if you encounter bugs or have suggestions for improvement!
