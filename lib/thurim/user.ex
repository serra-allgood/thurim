defmodule Thurim.User do
  @moduledoc """
  The User context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Thurim.Repo

  alias Thurim.User.Account
  alias Thurim.Devices
  alias Thurim.AccessTokens
  alias Thurim.Events.Event
  alias Thurim.User.Profile
  alias Thurim.User.AccountData
  alias Thurim.PushRules
  alias Thurim.Events

  @domain Application.get_env(:thurim, :matrix)[:domain]

  def localpart_available?(localpart) do
    get_account(localpart) == nil
  end

  def mx_user_id(localpart) do
    "@" <> localpart <> ":" <> @domain
  end

  def generate_localpart() do
    UUID.uuid4() |> Base.hex_encode32(padding: false, case: :lower)
  end

  def get_account_data(room_id, mx_user_id, since) do
    from(a in AccountData,
      where: a.room_id == ^room_id,
      where: a.localpart == ^extract_localpart(mx_user_id),
      where: a.inserted_at >= ^DateTime.from_unix!(since, :millisecond),
      select: %{"type" => a.type, "content" => a.content}
    )
    |> Repo.all()
  end

  def permission_to_create_event?(sender, room_id, event_type, is_state_event) do
    power_level_event =
      Events.latest_state_event_of_type_in_room_id(room_id, "m.room.power_levels", "")

    user_power_level = get_power_level(sender, room_id, power_level_event.content)

    minimum_power_level =
      if is_state_event do
        Map.get(power_level_event.content, "events", %{})
        |> Map.get(event_type, Map.get(power_level_event.content, "state_default", 50))
      else
        Map.get(power_level_event.content, "events", %{})
        |> Map.get(event_type, Map.get(power_level_event.content, "events_default", 0))
      end

    user_power_level >= minimum_power_level
  end

  def get_power_level(mx_user_id, room_id, power_levels) do
    room_creation = Events.latest_state_event_of_type_in_room_id(room_id, "m.room.create", "")
    is_room_creator = room_creation.content["creator"] == mx_user_id

    if is_room_creator do
      100
    else
      # Check if mx_user_id is listed under users key, otherwise default to users_default, and default to 0 if users_default is not present
      Map.get(power_levels, "users", %{})
      |> Map.get(mx_user_id, Map.get(power_levels, "users_default", 0))
    end
  end

  def create_profile(params \\ %{}) do
    %Profile{}
    |> Profile.changeset(params)
    |> Repo.insert()
  end

  def create_push_rules(attrs \\ %{}) do
    %AccountData{
      type: "m.default_push_rules",
      content: PushRules.default_push_rules(attrs["localpart"])
    }
    |> AccountData.changeset(attrs)
    |> Repo.insert()
  end

  def get_push_rules(localpart, room_id \\ "") do
    Repo.get_by(AccountData, localpart: localpart, room_id: room_id, type: "m.default_push_rules")
  end

  def authenticate(localpart, password) do
    with account when not is_nil(account) <- get_account(localpart),
         password_hash when not is_nil(password_hash) <- account.password_hash,
         true <- Bcrypt.verify_pass(password, password_hash) do
      {:ok, account}
    else
      _ -> {:error, :invalid_login}
    end
  end

  def register(params) do
    multi =
      Multi.new()
      |> Multi.insert(:account, Account.changeset(%Account{}, params))
      |> Multi.run(:device, fn _repo, _changes -> Devices.create_device(params) end)
      |> Multi.run(:profile, fn _repo, %{account: account} ->
        create_profile(%{"localpart" => account.localpart})
      end)
      |> Multi.run(:account_data, fn _repo, %{account: account} ->
        create_push_rules(%{"localpart" => account.localpart})
      end)
      |> Multi.run(:signed_access_token, fn _repo, %{device: device, account: account} ->
        AccessTokens.create_and_sign(device.session_id, account.localpart)
      end)

    Repo.transaction(multi)
  end

  def preload_account(account) do
    account |> Repo.preload([:devices, :access_tokens])
  end

  def user_ids_in_room(room) do
    from(
      e in Event,
      where: e.room_id == ^room.room_id,
      where: e.type == "m.room.member",
      group_by: [e.state_key],
      select: {e.state_key, fragment("array_agg(content->>'membership')")}
    )
    |> Repo.all()
    |> Enum.map(fn {user_id, memberships} -> {user_id, List.last(memberships)} end)
  end

  def membership_events_in_room(room_id, membership, not_membership, at_time) do
    join_types = ~w(join invite knock leave ban)

    base =
      from(e in Event,
        where:
          e.room_id == ^room_id and e.type == "m.room.member" and e.origin_server_ts < ^at_time,
        order_by: e.origin_server_ts
      )

    cond do
      not_membership != nil ->
        from(e in base,
          where:
            fragment("content->>'membership'") not in ^Enum.filter(
              join_types,
              &(&1 != not_membership)
            )
        )

      membership != nil ->
        from(e in base, where: fragment("content->>'membership'") == ^membership)

      true ->
        base
    end
    |> Repo.all()
  end

  def joined_user_ids_in_room(room_id) do
    from(e in Event,
      where: e.room_id == ^room_id and e.type == "m.room.member",
      where: e.content["membership"] == "join",
      select: {e.state_key, e.content["displayname"], e.content["avatar_url"]},
      order_by: e.origin_server_ts
    )
    |> Repo.all()
    |> Enum.group_by(
      fn {user_id, _displayname, _avatar_url} -> user_id end,
      fn {_user_id, displayname, avatar_url} ->
        %{"displayname" => displayname, "avatar_url" => avatar_url}
      end
    )
  end

  def extract_localpart(user_id) do
    [head | _tail] = String.split(user_id, ":", parts: 2)
    "@" <> localpart = head
    localpart
  end

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  def list_accounts_with_devices do
    Repo.all(Account) |> Repo.preload([:devices])
  end

  def get_account(localpart), do: Repo.get(Account, localpart)

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(localpart), do: Repo.get!(Account, localpart)

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end
end
