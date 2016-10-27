defmodule Etude.Request.Test do
  use ExUnit.Case

  setup_all do
    {:ok, _} = :application.ensure_all_started(:httparrot)
    :ok
  end

  test "makes several requests in parallel" do
    {a, b} = url("/get")
    |> Etude.Request.get()
    |> Etude.chain(fn(%{body: body}) ->
      [
        url("/post") |> Etude.Request.post(body),
        url("/put") |> Etude.Request.put(body)
      ]
      |> Etude.join()
    end)
    |> Etude.map(fn([%{body: a}, %{body: b}]) ->
      {Poison.decode!(a), Poison.decode!(b)}
    end)
    |> Etude.fork!()

    assert a["json"]["url"] == b["json"]["url"]
  end

  defp url(path) do
    {:ok, port} = Application.fetch_env(:httparrot, :http_port)
    "http://localhost:#{port}#{path}"
  end
end
