defmodule Thurim.SnapshotsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Thurim.Snapshots` context.
  """

  @doc """
  Generate a snapshot.
  """
  def snapshot_fixture(attrs \\ %{}) do
    {:ok, snapshot} =
      attrs
      |> Enum.into(%{

      })
      |> Thurim.Snapshots.create_snapshot()

    snapshot
  end
end
