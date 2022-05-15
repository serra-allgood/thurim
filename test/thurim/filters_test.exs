# defmodule Thurim.FiltersTest do
#   use Thurim.DataCase

#   alias Thurim.Filters

#   describe "filters" do
#     alias Thurim.Filters.Filter

#     @valid_attrs %{filter: %{}, localpart: "some localpart"}
#     @update_attrs %{filter: %{}, localpart: "some updated localpart"}
#     @invalid_attrs %{filter: nil, localpart: nil}

#     def filter_fixture(attrs \\ %{}) do
#       {:ok, filter} =
#         attrs
#         |> Enum.into(@valid_attrs)
#         |> Filters.create_filter()

#       filter
#     end

#     test "list_filters/0 returns all filters" do
#       filter = filter_fixture()
#       assert Filters.list_filters() == [filter]
#     end

#     test "create_filter/1 with valid data creates a filter" do
#       assert {:ok, %Filter{} = filter} = Filters.create_filter(@valid_attrs)
#       assert filter.filter == %{}
#       assert filter.localpart == "some localpart"
#     end

#     test "create_filter/1 with invalid data returns error changeset" do
#       assert {:error, %Ecto.Changeset{}} = Filters.create_filter(@invalid_attrs)
#     end

#     test "update_filter/2 with valid data updates the filter" do
#       filter = filter_fixture()
#       assert {:ok, %Filter{} = filter} = Filters.update_filter(filter, @update_attrs)
#       assert filter.filter == %{}
#       assert filter.localpart == "some updated localpart"
#     end

#     test "change_filter/1 returns a filter changeset" do
#       filter = filter_fixture()
#       assert %Ecto.Changeset{} = Filters.change_filter(filter)
#     end
#   end
# end
