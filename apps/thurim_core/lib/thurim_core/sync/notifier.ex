defmodule ThurimCore.Sync.Notifier do
  @pubsub ThurimCore.PubSub

  def room_topic(room_id), do: "sync:room:#{room_id}"
  def user_topic(user_id), do: "sync:user:#{user_id}"
  def device_topic(device_id), do: "sync:device:#{device_id}"

  def subscribe(topic), do: Phoenix.PubSub.subscribe(@pubsub, topic)
  def unsubscribe(topic), do: Phoenix.PubSub.unsubscribe(@pubsub, topic)

  def notify_room_update(room_id) do
    notify(room_topic(room_id))
  end

  def notify_user_update(user_id) do
    notify(user_topic(user_id))
  end

  def notify_device_update(device_id) do
    notify(device_topic(device_id))
  end

  defp notify(topic) do
    Phoenix.PubSub.broadcast(@pubsub, topic, :sync_update)
  end
end
