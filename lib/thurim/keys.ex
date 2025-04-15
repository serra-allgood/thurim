defmodule Thurim.Keys do
  require Logger

  @moduledoc """
  The Keys context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Thurim.Repo
  alias Thurim.Devices.Device
  alias Thurim.Keys.{CrossSigningKey, DeviceKey, KeyBackup, OneTimeKey, RoomKey}

  @etag_length 6

  def backup_exists?(account) do
    from(kb in KeyBackup, where: kb.localpart == ^account.localpart)
    |> Repo.exists?()
  end

  def claim_one_time_keys(one_time_keys) do
    response =
      Enum.reduce(one_time_keys, %{}, fn {mx_user_id, device_algorithm}, acc ->
        value =
          Enum.reduce(device_algorithm, %{}, fn {device_id, algorithm}, acc ->
            one_time_key =
              from(otk in OneTimeKey,
                where: otk.device_id == ^device_id,
                where: otk.algorithm == ^algorithm,
                limit: 1
              )
              |> Repo.one()

            case Repo.delete(one_time_key) do
              {:ok, one_time_key} ->
                value =
                  %{
                    "#{one_time_key.algorithm}:#{one_time_key.key_id}" => %{
                      "key" => one_time_key.key,
                      "signatures" => one_time_key.signatures
                    }
                  }

                Map.put(acc, device_id, value)

              {:error, _} ->
                acc
            end
          end)

        Map.put(acc, mx_user_id, value)
      end)

    {:ok, %{"one_time_keys" => response}}
  end

  def show_version_response(account) do
    key_backup = get_key_backup(account.localpart)

    %{
      algorithm: key_backup.algorithm,
      auth_data: key_backup.auth_data,
      etag: key_backup.etag,
      version: key_backup.version,
      count:
        from(kb in KeyBackup,
          where: kb.id == ^key_backup.id,
          join: rk in RoomKey,
          on: rk.key_backup_id == kb.id,
          select: count(rk.id)
        )
        |> Repo.one()
    }
  end

  def generate_backup_etag() do
    :crypto.strong_rand_bytes(@etag_length)
    |> Base.url_encode64(padding: false, ignore: :whitespace)
    |> binary_part(0, @etag_length)
  end

  def backup_room_keys(room_keys, account) do
    key_backup = get_key_backup(account.localpart)
    multi = Multi.new()

    %{count: count, multi: multi} =
      Enum.reduce(room_keys, %{count: 0, multi: multi}, fn {room_id, sessions}, acc ->
        attrs = %{room_id: room_id, sessions: sessions, key_backup_id: key_backup.id}

        multi =
          acc.multi
          |> Multi.insert("room_key_for_#{room_id}", RoomKey.changeset(%RoomKey{}, attrs))

        %{acc | count: acc.count + 1, multi: multi}
      end)

    new_etag = generate_backup_etag()

    multi
    |> Multi.update(multi, :update_etag, KeyBackup.changeset(key_backup, %{etag: new_etag}))

    case Repo.transaction(multi) do
      {:ok, _} -> {:ok, %{count: count, etag: new_etag}}
      {:error, _, _, _} -> :error
    end
  end

  def get_keys(account) do
    key_backup = get_key_backup(account.localpart)

    query =
      from(rk in RoomKey,
        where: rk.key_backup_id == ^key_backup.id,
        select: %{room_id: rk.room_id, sessions: rk.sessions}
      )
      |> Repo.all()

    %{
      rooms:
        Enum.reduce(query, %{}, fn %{room_id: room_id, sessions: sessions}, acc ->
          Map.put(acc, room_id, sessions)
        end)
    }
  end

  def get_key_backup(localpart) do
    Repo.get_by(KeyBackup, localpart: localpart)
  end

  def process_cross_signing_key(_sender, key) when is_nil(key), do: {:ok, nil}

  def process_cross_signing_key(sender, key) do
    params = %{
      mx_user_id: sender,
      usage: key["usage"],
      keys: key["keys"],
      signatures: key["signatures"]
    }

    create_cross_signing_key(params)
  end

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

  def query_keys(query) do
    %{device_keys: Enum.reduce(query, %{}, &query_key_helper/2)}
  end

  defp query_key_helper({mx_user_id, []}, acc) do
    device_keys =
      from(dk in DeviceKey,
        join: d in Device,
        on: d.device_id == dk.device_id,
        where: d.mx_user_id == ^mx_user_id,
        select: %{
          algorithms: dk.algorithms,
          device_id: dk.device_id,
          keys: dk.keys,
          signatures: dk.signatures,
          display_name: d.display_name
        }
      )
      |> Repo.all()

    Map.put(
      acc,
      mx_user_id,
      Enum.reduce(device_keys, %{}, fn key, acc ->
        Map.put(acc, key.device_id, %{
          algorithms: key.algorithms,
          device_id: key.device_id,
          keys: key.keys,
          signatures: key.signatures,
          user_id: mx_user_id,
          unsigned: %{
            display_name: key.display_name
          }
        })
      end)
    )
  end

  defp query_key_helper({mx_user_id, device_ids}, acc) do
    device_keys =
      from(dk in DeviceKey,
        join: d in Device,
        on: d.device_id == dk.device_id,
        where: d.mx_user_id == ^mx_user_id,
        where: d.device_id in ^device_ids,
        select: %{
          algorithms: dk.algorithms,
          device_id: dk.device_id,
          keys: dk.keys,
          signatures: dk.signatures,
          display_name: d.display_name
        }
      )
      |> Repo.all()

    Map.put(
      acc,
      mx_user_id,
      Enum.reduce(device_keys, %{}, fn key, acc ->
        Map.put(acc, key.device_id, %{
          algorithms: key.algorithms,
          device_id: key.device_id,
          keys: key.keys,
          signatures: key.signatures,
          user_id: mx_user_id,
          unsigned: %{
            display_name: key.display_name
          }
        })
      end)
    )
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

  def create_cross_signing_key(attrs \\ %{}) do
    %CrossSigningKey{}
    |> CrossSigningKey.changeset(attrs)
    |> Repo.insert()
  end

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
