defmodule Thurim.EventsFixtures do
  alias Thurim.Events

  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        event_id: Events.generate_event_id()
      })
      |> Events.create_event()

    event
  end
end
