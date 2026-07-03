defmodule ThurimCore.Utils do
  def then_if(arg, true, func), do: func.(arg)
  def then_if(arg, false, _func), do: arg

  def then_if(arg, condition_func, func) do
    if condition_func.(arg) do
      func.(arg)
    else
      arg
    end
  end
end
