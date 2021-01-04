defmodule Thurim.AccessTokensTest do
  use Thurim.DataCase

  alias Thurim.AccessTokens

  describe "access_tokens" do
    alias Thurim.AccessTokens.AccessToken

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def access_token_fixture(attrs \\ %{}) do
      {:ok, access_token} =
        attrs
        |> Enum.into(@valid_attrs)
        |> AccessTokens.create_access_token()

      access_token
    end

    test "list_access_tokens/0 returns all access_tokens" do
      access_token = access_token_fixture()
      assert AccessTokens.list_access_tokens() == [access_token]
    end

    test "get_access_token!/1 returns the access_token with given id" do
      access_token = access_token_fixture()
      assert AccessTokens.get_access_token!(access_token.id) == access_token
    end

    test "create_access_token/1 with valid data creates a access_token" do
      assert {:ok, %AccessToken{} = access_token} = AccessTokens.create_access_token(@valid_attrs)
    end

    test "create_access_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AccessTokens.create_access_token(@invalid_attrs)
    end

    test "update_access_token/2 with valid data updates the access_token" do
      access_token = access_token_fixture()
      assert {:ok, %AccessToken{} = access_token} = AccessTokens.update_access_token(access_token, @update_attrs)
    end

    test "update_access_token/2 with invalid data returns error changeset" do
      access_token = access_token_fixture()
      assert {:error, %Ecto.Changeset{}} = AccessTokens.update_access_token(access_token, @invalid_attrs)
      assert access_token == AccessTokens.get_access_token!(access_token.id)
    end

    test "delete_access_token/1 deletes the access_token" do
      access_token = access_token_fixture()
      assert {:ok, %AccessToken{}} = AccessTokens.delete_access_token(access_token)
      assert_raise Ecto.NoResultsError, fn -> AccessTokens.get_access_token!(access_token.id) end
    end

    test "change_access_token/1 returns a access_token changeset" do
      access_token = access_token_fixture()
      assert %Ecto.Changeset{} = AccessTokens.change_access_token(access_token)
    end
  end
end
