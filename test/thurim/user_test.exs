defmodule Thurim.UserTest do
  use Thurim.DataCase

  alias Thurim.User

  describe "accounts" do
    alias Thurim.User.Account

    @valid_attrs %{is_deactivated: false, localpart: "some_localpart", password: "some password"}
    @update_attrs %{is_deactivated: true, localpart: "some_updated_localpart", password: "some updated password"}
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
      assert account.localpart == "some_localpart"
      assert Bcrypt.verify_pass("some password", account.password_hash)
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = User.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_without_password()
      assert {:ok, %Account{} = account} = User.update_account(account, @update_attrs)
      assert account.is_deactivated == true
      assert account.localpart == "some_updated_localpart"
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
end
