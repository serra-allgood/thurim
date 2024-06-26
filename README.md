# Thurim

Thurim is a [Matrix](https://matrix.org) homeserver implementation written in Elixir with the Phoenix framework. It is inspired in part by [Plasma](https://gitlab.com/beerfactory.org/plasma) as well as [Dendrite](https://github.com/matrix-org/dendrite).

The project has just begun and collaborators are more than welcome. Come discuss the project at [#thurim:mozilla.org](https://matrix.to/#/#thurim:mozilla.org).

## Dependencies

Thurim is developed against:

* Erlang 26.0.1
* Elixir 1.14.5
* Postgresql 14.8

## Installation

After cloning the repo:

* Install dependencies with `mix deps.get`
* Create self-signed X.509 certificate: `mkdir -p priv/cert/; openssl req -x509 -newkey rsa:4096 -keyout priv/cert/selfsigned_key.pem -out priv/cert/selfsigned.pem -sha256 -days 365 -nodes`
* Create and migrate your database with `mix ecto.setup`
* Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Contributing Guidelines

External help is for sure appreciated it! I hope to give this project more love by creating some issues for collaborators to pick from. In the meantime, please feel free to open issues you see upon reviewing the code. Elixir is **not** my first language and I am very far from being an expert in it.

For a general idea as to where you can contribute, my development efforts have been focused on the Client-Server spec implementation. Please feel free to work on:
- The Server-Server implementation
  - In particular, the state resolution algorithm would be a great thing to implement/propose
- The Application Service API
- Suggestions to improve the data model
