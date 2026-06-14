defmodule ThurimClientApi.RateLimit.RateLimitInfo do
  defstruct scale: 0, limit: 0

  def new do
    %__MODULE__{}
  end

  def set_limit(%__MODULE__{} = info, limit), do: %__MODULE__{info | limit: limit}

  def set_scale(%__MODULE__{} = info, scale), do: %__MODULE__{info | scale: scale}
end
