defmodule Thurim.Devices do
  import Ecto.Query, warn: false
  alias Thurim.User
  alias Thurim.Repo
  alias Thurim.Devices.{Device, DeviceListVersion}
  alias Thurim.{AccessTokens, Globals}

  @device_id_length 6

  def generate_device_id(localpart) do
    device_id =
      :crypto.strong_rand_bytes(@device_id_length)
      |> Base.url_encode64(padding: false, ignore: :whitespace)
      |> binary_part(0, @device_id_length)

    if get_by_device_id(device_id, localpart) |> is_nil() do
      device_id
    else
      generate_device_id(localpart)
    end
  end

  def increment_device_list_version(mx_user_id) do
    case from(dv in DeviceListVersion, where: dv.user_id == ^mx_user_id) |> Repo.one() do
      nil ->
        %DeviceListVersion{}
        |> DeviceListVersion.changeset(%{
          user_id: mx_user_id,
          version: Globals.next_sync_count()
        })
        |> Repo.insert()

      dv ->
        dv
        |> DeviceListVersion.changeset(%{user_id: mx_user_id, version: Globals.next_sync_count()})
        |> Repo.update()
    end
  end

  def get_by_device_id(device_id, localpart) do
    case from(d in Device, where: d.device_id == ^device_id and d.localpart == ^localpart)
         |> Repo.one() do
      nil -> nil
      device -> device |> Repo.preload(:access_token)
    end
  end

  def create_device_and_access_token(attrs) do
    with {:ok, device} <- create_device(attrs),
         {:ok, _} <-
           AccessTokens.create_access_token(%{
             device_session_id: device.session_id,
             localpart: attrs.localpart
           }),
         {:ok, _} <-
           increment_device_list_version(User.mx_user_id(attrs.localpart)) do
      device |> Repo.preload(:access_token)
    end
  end

  @doc """
  Returns the list of devices.

  ## Examples

      iex> list_devices()
      [%Device{}, ...]

  """
  def list_devices(localpart) do
    from(d in Device, where: d.localpart == ^localpart)
    |> Repo.all()
  end

  @doc """
  Gets a single device.

  Raises `Ecto.NoResultsError` if the Device does not exist.

  ## Examples

      iex> get_device!(123)
      %Device{}

      iex> get_device!(456)
      ** (Ecto.NoResultsError)

  """
  def get_device!(id), do: Repo.get!(Device, id)

  @doc """
  Creates a device.

  ## Examples

      iex> create_device(%{field: value})
      {:ok, %Device{}}

      iex> create_device(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_device(attrs \\ %{}) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a device.

  ## Examples

      iex> update_device(device, %{field: new_value})
      {:ok, %Device{}}

      iex> update_device(device, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a device.

  ## Examples

      iex> delete_device(device)
      {:ok, %Device{}}

      iex> delete_device(device)
      {:error, %Ecto.Changeset{}}

  """
  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end

  def delete_devices(devices) do
    ids = devices |> Enum.map(& &1.session_id)

    from(d in Device, where: d.session_id in ^ids)
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking device changes.

  ## Examples

      iex> change_device(device)
      %Ecto.Changeset{data: %Device{}}

  """
  def change_device(%Device{} = device, attrs \\ %{}) do
    Device.changeset(device, attrs)
  end
end
