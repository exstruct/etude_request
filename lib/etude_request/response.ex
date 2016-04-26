defmodule Etude.Request.Error do
  defexception reason: nil,
               url: nil

  def message(%{url: url, reason: reason}) do
    "error #{inspect(reason)} for #{inspect(url)}"
  end
end

defmodule Etude.Request.Response do
  defmodule Status do
    defstruct request: nil
  end

  defmodule Headers do
    defstruct request: nil
  end

  defmodule Body do
    defstruct request: nil
  end
end

defimpl Etude.Thunk, for: [Etude.Request.Response.Status,
                           Etude.Request.Response.Headers,
                           Etude.Request.Response.Body] do
  def resolve(thunk = %{request: request}, state) do
    case request.(state) do
      {:await, request, state} ->
        {:await, %{thunk | request: request}, state}
      {id, state} ->
        fetch(id, state, thunk)
    end
  end

  defp fetch(id, state, thunk) do
    private = state.private
    case Map.fetch(private, {@for, id}) do
      :error ->
        {:await, thunk, state}
      {:ok, %Etude.Request.Error{} = error} ->
        raise error
      {:ok, value} ->
        {value, state}
    end
  end
end
