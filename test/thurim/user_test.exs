defmodule Thurim.UserTest do
  use Thurim.DataCase

  alias Thurim.User

  describe "accounts" do
    alias Thurim.User.Account

    @valid_attrs %{is_deactivated: false, localpart: "some localpart", password: "some password"}
    @update_attrs %{is_deactivated: true, localpart: "some updated localpart", password: "some updated password"}
    @invalid_attrs %{is_deactivated: nil, localpart: nil, password: nil}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@valid_attrs)
        |> User.create_account()

      account
    end

    def account_without_password(_attrs \\ %{}) do
      %{account_fixture() | password: nil}
    end

    test "list_accounts/0 returns all accounts" do
      account = account_without_password()
      assert User.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_without_password()
      assert User.get_account!(account.localpart) == account
    end

    test "create_account/1 with valid data creates a account" do
      assert {:ok, %Account{} = account} = User.create_account(@valid_attrs)
      assert account.is_deactivated == false
      assert account.localpart == "some localpart"
      assert Bcrypt.verify_pass("some password", account.password_hash)
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = User.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_without_password()
      assert {:ok, %Account{} = account} = User.update_account(account, @update_attrs)
      assert account.is_deactivated == true
      assert account.localpart == "some updated localpart"
      assert Bcrypt.verify_pass("some updated password", account.password_hash)
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_without_password()
      assert {:error, %Ecto.Changeset{}} = User.update_account(account, @invalid_attrs)
      assert account == User.get_account!(account.localpart)
    end

    test "delete_account/1 deletes the account" do
      account = account_without_password()
      assert {:ok, %Account{}} = User.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> User.get_account!(account.localpart) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_without_password()
      assert %Ecto.Changeset{} = User.change_account(account)
    end
  end

  describe "devices" do
    alias Thurim.User.Device

    @valid_attrs %{access_token: "some access_token", device_id: "some device_id", display_name: "some display_name", ip: "some ip", last_seen_ts: ~N[2010-04-17 14:00:00], user_agent: "some user_agent"}
    @update_attrs %{access_token: "some updated access_token", device_id: "some updated device_id", display_name: "some updated display_name", ip: "some updated ip", last_seen_ts: ~N[2011-05-18 15:01:01], user_agent: "some updated user_agent"}
    @invalid_attrs %{access_token: nil, device_id: nil, display_name: nil, ip: nil, last_seen_ts: nil, user_agent: nil}

    def device_fixture(attrs \\ %{}) do
      {:ok, device} =
        attrs
        |> Enum.into(@valid_attrs)
        |> User.create_device()

      device
    end

    test "list_devices/0 returns all devices" do
      device = device_fixture()
      assert User.list_devices() == [device]
    end

    test "get_device!/1 returns the device with given id" do
      device = device_fixture()
      assert User.get_device!(device.id) == device
    end

    test "create_device/1 with valid data creates a device" do
      assert {:ok, %Device{} = device} = User.create_device(@valid_attrs)
      assert device.access_token == "some access_token"
      assert device.device_id == "some device_id"
      assert device.display_name == "some display_name"
      assert device.ip == "some ip"
      assert device.last_seen_ts == ~N[2010-04-17 14:00:00]
      assert device.user_agent == "some user_agent"
    end

    test "create_device/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = User.create_device(@invalid_attrs)
    end

    test "update_device/2 with valid data updates the device" do
      device = device_fixture()
      assert {:ok, %Device{} = device} = User.update_device(device, @update_attrs)
      assert device.access_token == "some updated access_token"
      assert device.device_id == "some updated device_id"
      assert device.display_name == "some updated display_name"
      assert device.ip == "some updated ip"
      assert device.last_seen_ts == ~N[2011-05-18 15:01:01]
      assert device.user_agent == "some updated user_agent"
    end

    test "update_device/2 with invalid data returns error changeset" do
      device = device_fixture()
      assert {:error, %Ecto.Changeset{}} = User.update_device(device, @invalid_attrs)
      assert device == User.get_device!(device.id)
    end

    test "delete_device/1 deletes the device" do
      device = device_fixture()
      assert {:ok, %Device{}} = User.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> User.get_device!(device.id) end
    end

    test "change_device/1 returns a device changeset" do
      device = device_fixture()
      assert %Ecto.Changeset{} = User.change_device(device)
    end
  end
end
