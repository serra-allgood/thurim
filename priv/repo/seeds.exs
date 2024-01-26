# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Thurim.Repo.insert!(%Thurim.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Thurim.Repo.insert!(%Thurim.Globals.GlobalCount{name: "sync", count: 0})
