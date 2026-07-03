defmodule ThurimCore.Filtering do
  import Ecto.Query, warn: false
  alias ThurimCore.{Filtering.Filter, Repo}

  def create_filter(user_id, attrs) do
    %Filter{user_id: user_id}
    |> Filter.changeset(attrs)
    |> Repo.insert()
  end

  def get_filter(user_id, filter_id) do
    from(f in Filter, where: f.user_id == ^user_id and f.filter_id == ^filter_id)
    |> Repo.one()
  end
end
