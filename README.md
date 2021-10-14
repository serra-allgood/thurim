# Thurim

Thurim is a [Matrix](https://matrix.org) homeserver implementation written in Elixir with the Phoenix framework. It is inspired in part by [Plasma](https://gitlab.com/beerfactory.org/plasma) as well as [Dendrite](https://github.com/matrix-org/dendrite).

The project has just begun and collaborators are more than welcome. Come discuss the project at [#thurim:mozilla.org](https://matrix.to/#/#thurim:mozilla.org).

## Dependencies

Thurim is developed against:

* Erlang 22.2.1
* Elixir 1.12.3
* Postgresql 13.0

## Installation

After cloning the repo:

* Install dependencies with `mix deps.get`
* Create and migrate your database with `mix ecto.setup`
* Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
