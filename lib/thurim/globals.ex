defmodule Thurim.Globals do
  import Ecto.Query, warn: false
  alias Thurim.{Repo, Globals.GlobalCount}

  def current_sync_count() do
    from(g in GlobalCount, where: g.name == "sync", select: g.count)
    |> Repo.one()
  end

  def next_sync_count() do
    current_sync =
      from(g in GlobalCount, where: g.name == "sync")
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
