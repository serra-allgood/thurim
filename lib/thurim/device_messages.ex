defmodule Thurim.DeviceMessages do
  import Ecto.Query, warn: false
  alias Thurim.{DeviceMessages.DeviceMessage, Devices.Device, Repo}

  def get_device_messages(mx_user_id, device_id, since) do
    from(dm in DeviceMessage,
      where: dm.mx_user_id == ^mx_user_id,
      where: dm.device_id == ^device_id,
      where: dm.count > ^since,
      select: %{sender: dm.sender, type: dm.type, content: dm.content}
    )
    |> Repo.all()
  end

  def max_device_message_count(mx_user_id, device_id) do
    from(dm in DeviceMessage,
      where: dm.mx_user_id == ^mx_user_id,
      where: dm.device_id == ^device_id,
      select: coalesce(max(dm.count), 0)
    )
    |> Repo.one()
  end

  def send_to_device(params) do
    %DeviceMessage{}
    |> DeviceMessage.changeset(params)
    |> Repo.insert()
  end

  def send_to_all_devices(mx_user_id, params) do
    from(d in Device, where: d.mx_user_id == ^mx_user_id, select: d.device_id)
    |> Repo.all()
    |> Enum.each(fn device_id ->
      send_to_device(Map.put(params, "device_id", device_id))
    end)
  end
end
