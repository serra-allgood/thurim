defmodule Thurim.DeviceKeys do
  require Logger

  @moduledoc """
  The Keys context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.DeviceKeys.{DeviceKey, OneTimeKey}

  def process_device_keys(device_keys) when is_nil(device_keys) do
    {:ok, nil}
  end

  def process_device_keys(device_keys) do
    Logger.debug(device_keys)

    params = %{
      device_id: device_keys["device_id"],
      algorithms: device_keys["algorithms"],
      keys: device_keys["keys"],
      signatures: device_keys["signatures"]
    }

    create_device_key(params)
  end

  def process_one_time_keys(device, one_time_keys) when is_nil(one_time_keys),
    do: {:ok, %{one_time_keys: get_one_time_key_counts(device)}}

  def process_one_time_keys(device, one_time_keys) do
    one_time_keys
    |> Enum.each(fn {key, value} ->
      [algorithm, key_id] = String.split(key, ":")

      params = %{
        device_id: device.device_id,
        key_id: key_id,
        algorithm: algorithm,
        key: value["key"],
        signatures: value["signatures"]
      }

      case create_one_time_key(params) do
        {:ok, _} ->
          nil

        {:error, changeset} ->
          Logger.error("Failed to create one time key: #{inspect(changeset, pretty: true)}")
      end
    end)

    {:ok, %{one_time_keys: get_one_time_key_counts(device)}}
  end

  def get_one_time_key_counts(device) do
    from(o in OneTimeKey,
      select: %{o.algorithm => count(o.id)},
      group_by: o.algorithm,
      where: o.device_id == ^device.device_id
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of keys.

  ## Examples

      iex> list_keys()
      [%Key{}, ...]

  """
  def list_keys do
    Repo.all(Key)
  end

  @doc """
  Gets a single key.

  Raises `Ecto.NoResultsError` if the Key does not exist.

  ## Examples

      iex> get_key!(123)
      %Key{}

      iex> get_key!(456)
      ** (Ecto.NoResultsError)

  """
  def get_key!(id), do: Repo.get!(Key, id)

  @doc """
  Creates a key.

  ## Examples

      iex> create_key(%{field: value})
      {:ok, %Key{}}

      iex> create_key(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_device_key(attrs \\ %{}) do
    %DeviceKey{}
    |> DeviceKey.changeset(attrs)
    |> Repo.insert()
  end

  def create_one_time_key(attrs \\ %{}) do
    %OneTimeKey{}
    |> OneTimeKey.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a key.

  ## Examples

      iex> update_key(key, %{field: new_value})
      {:ok, %Key{}}

      iex> update_key(key, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_key(%DeviceKey{} = key, attrs) do
    key
    |> DeviceKey.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a key.

  ## Examples

      iex> delete_key(key)
      {:ok, %Key{}}

      iex> delete_key(key)
      {:error, %Ecto.Changeset{}}

  """
  def delete_key(%DeviceKey{} = key) do
    Repo.delete(key)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking key changes.

  ## Examples

      iex> change_key(key)
      %Ecto.Changeset{data: %Key{}}

  """
  def change_key(%DeviceKey{} = key, attrs \\ %{}) do
    DeviceKey.changeset(key, attrs)
  end
end
