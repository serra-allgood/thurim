defmodule Thurim.AccountDataTest do
  use Thurim.DataCase

  alias Thurim.AccountData

  describe "account_data" do
    alias Thurim.AccountData.AccountDatum

    @valid_attrs %{content: "some content", localpart: "some localpart", room_id: "some room_id", type: "some type"}
    @update_attrs %{content: "some updated content", localpart: "some updated localpart", room_id: "some updated room_id", type: "some updated type"}
    @invalid_attrs %{content: nil, localpart: nil, room_id: nil, type: nil}

    def account_datum_fixture(attrs \\ %{}) do
      {:ok, account_datum} =
        attrs
        |> Enum.into(@valid_attrs)
        |> AccountData.create_account_datum()

      account_datum
    end

    test "list_account_data/0 returns all account_data" do
      account_datum = account_datum_fixture()
      assert AccountData.list_account_data() == [account_datum]
    end

    test "get_account_datum!/1 returns the account_datum with given id" do
      account_datum = account_datum_fixture()
      assert AccountData.get_account_datum!(account_datum.id) == account_datum
    end

    test "create_account_datum/1 with valid data creates a account_datum" do
      assert {:ok, %AccountDatum{} = account_datum} = AccountData.create_account_datum(@valid_attrs)
      assert account_datum.content == "some content"
      assert account_datum.localpart == "some localpart"
      assert account_datum.room_id == "some room_id"
      assert account_datum.type == "some type"
    end

    test "create_account_datum/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AccountData.create_account_datum(@invalid_attrs)
    end

    test "update_account_datum/2 with valid data updates the account_datum" do
      account_datum = account_datum_fixture()
      assert {:ok, %AccountDatum{} = account_datum} = AccountData.update_account_datum(account_datum, @update_attrs)
      assert account_datum.content == "some updated content"
      assert account_datum.localpart == "some updated localpart"
      assert account_datum.room_id == "some updated room_id"
      assert account_datum.type == "some updated type"
    end

    test "update_account_datum/2 with invalid data returns error changeset" do
      account_datum = account_datum_fixture()
      assert {:error, %Ecto.Changeset{}} = AccountData.update_account_datum(account_datum, @invalid_attrs)
      assert account_datum == AccountData.get_account_datum!(account_datum.id)
    end

    test "delete_account_datum/1 deletes the account_datum" do
      account_datum = account_datum_fixture()
      assert {:ok, %AccountDatum{}} = AccountData.delete_account_datum(account_datum)
      assert_raise Ecto.NoResultsError, fn -> AccountData.get_account_datum!(account_datum.id) end
    end

    test "change_account_datum/1 returns a account_datum changeset" do
      account_datum = account_datum_fixture()
      assert %Ecto.Changeset{} = AccountData.change_account_datum(account_datum)
    end
  end
end
