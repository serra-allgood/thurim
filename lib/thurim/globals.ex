defmodule Thurim.Globals do
  import Ecto.Query, warn: false
  alias Thurim.{Repo, Globals.GlobalCount}

  def next_sync_count() do
    current_sync =
      from(c in GlobalCount, where: c.name == "sync")
      |> Repo.one()

    new_sync =
      current_sync
      |> change_global(%{count: current_sync.count + 1})
      |> Repo.update!()

    new_sync.count
  end

  def change_global(%GlobalCount{} = global, attrs) do
    GlobalCount.changeset(global, attrs)
  end
end
