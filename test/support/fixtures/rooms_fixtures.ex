defmodule Thurim.RoomsFixtures do
  alias Thurim.Rooms

  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        room_id: Rooms.generate_room_id()
      })
      |> Rooms.create_room()

    room
  end
end
