![thurim-logo.png](./thurim-logo.png)

# Thurim

Thurim is a [Matrix](https://matrix.org) homeserver implementation written in Elixir with the Phoenix framework. It is inspired in part by [Plasma](https://gitlab.com/beerfactory.org/plasma) as well as [Dendrite](https://github.com/matrix-org/dendrite).

The project has just begun and collaborators are more than welcome. Come discuss the project at [#thurim:mozilla.org](https://matrix.to/#/#thurim:mozilla.org).

## Dependencies

Thurim is developed against:

* Erlang 29.0.2
* Elixir 1.20.1

## Matrix Specification

Thurim currently targets [v1.18](https://spec.matrix.org/v1.18/) of the spec.

## Development & Testing

### Installation

After cloning the repo:

* Install dependencies with `mix deps.get`
* Create and migrate your database with `mix ecto.setup`
* Start Phoenix endpoint with `mix phx.server`

### Testing

Tests cases are not a priority and eventually [Complement](https://github.com/matrix-org/complement) will be setup to serve as the test framework for Thurim.

## Contributing

Contributors are more than welcome. I suggest you start with the media or appservice
sub-apps! As of June 2026, my priorities are in the following order:

1. Client-Server API
2. Server-Server API
3. Describing how to deploy Thurim
4. Appservice API
5. Media API

Figuring out how to easily deploy Thurim is something I'd love thoughts on actually!

### Policy on AI

I've been a detractor of AI for a long time, mostly due to negative effects it has on
the world, including environmental and economic. However, as of June 2026, I started to
explore its usage and found it to be suprisingly useful, as long as I think about the
output of the model critically. For this reason, I'm tentatively comfortable with
contributors using AI, though I draw the line at unreviewed code and PR summaries
that are AI output. If you want to use AI, use it appropriately, not willy-nilly.

## Logo Credit

The lovely rune droplet logo for Thurim was created by @amazing_Ekka@ohai.social on the Fediverse!
