defmodule ThurimClientApi.AuthSession do
  alias ThurimCore.Cache.AuthSessionCache

  defstruct id: nil, completed_stages: [], auth_completed: false

  def new do
    session_id = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    set_session(%__MODULE__{id: session_id, completed_stages: [], auth_completed: false})
  end

  def add_completed_stages(%__MODULE__{} = session, type) do
    set_session(%__MODULE__{
      session
      | completed_stages: [type | session.completed_stages]
    })
  end

  def get_session(session_id) do
    AuthSessionCache.get(session_id)
  end

  def set_session(session) do
    case AuthSessionCache.put(session.id, session) do
      :ok ->
        session

      error ->
        error
    end
  end
end
