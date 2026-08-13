# Thurim Copilot Instructions

## Commands

Thurim is an Elixir umbrella project. Use Erlang 29.0.2 and Elixir 1.20.1.

```sh
# Fetch dependencies and create/migrate the PostgreSQL database
mix deps.get
mix ecto.setup

# Compile all umbrella applications
mix compile

# Start the public Phoenix gateway
mix phx.server

# Run all tests
mix test

# Run one application's tests or one test file from the umbrella root
mix test apps/thurim_client_api/test
mix test apps/thurim_client_api/test/thurim_client_api/controllers/error_json_test.exs

# Run one test by its source line
mix test apps/thurim_client_api/test/thurim_client_api/controllers/error_json_test.exs:4

# Format or check formatting
mix format
mix format --check-formatted
```

Tests use PostgreSQL through `ThurimCore.Repo`; the default test database credentials are
`postgres`/`postgres` on localhost. Application test aliases create and migrate the test
database before their tests.

## Architecture

- `apps/thurim_core` is the shared Matrix domain and persistence layer. It owns the PostgreSQL
  repo, schemas, migrations, account/token handling, room/event construction, signing, and
  event-DAG projections.
- `apps/thurim_api_helpers` provides cross-API router pipelines, Matrix-shaped JSON errors,
  access-token extraction/verification, interactive authentication, and rate-limiting support.
- `apps/thurim_gateway` is the public Phoenix entry point. It owns `/.well-known/matrix/*` and
  forwards `/_matrix` traffic to the protocol applications.
- `apps/thurim_client_api`, `apps/thurim_federation`, `apps/thurim_appservice`, and
  `apps/thurim_media` implement the client-server, server-server, application-service, and media
  APIs respectively. The gateway depends on and mounts each of them.
- All applications share the root `config/`, `_build/`, `deps/`, and `mix.lock`. Global Matrix
  configuration lives under `config :thurim_core, :matrix`; environment overrides are loaded last
  from `config/{dev,test,prod}.exs`.

## Conventions

- Implement Matrix behavior against specifications v1.18 and v1.19. Keep request maps string-keyed and use
  Matrix wire names and `errcode` values in responses.
- Client and media routers use `ThurimApiHelpers.ThurimRouter`. Put protected routes behind
  `:access_token`, which assigns `:current_user`, `:current_device`, and `:access_token`; use
  `:interactive_auth` or `:maybe_interactive_auth` for UIA routes. Keep client routes sorted by
  controller name and then path.
- Controllers that `use ThurimClientApi, :controller` import
  `ThurimApiHelpers.Errors`; use `json_error/2` for defined Matrix errors rather than introducing
  ad-hoc response shapes.
- Persist multi-record domain changes with `Ecto.Multi` and `Repo.transact/1`. For room events,
  build/sign events through `ThurimCore.Events` and maintain event edges and current-state
  projections within the same transaction.
- Database tests use `ThurimCore.DataCase`; connection tests use the application `ConnCase`.
  Both set up the SQL sandbox, so use these templates rather than managing sandbox ownership in
  individual tests.
- Run `mix format` from the umbrella root. The root formatter delegates to every application;
  app formatters import Phoenix formatting rules.
