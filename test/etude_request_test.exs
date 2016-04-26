defmodule Etude.Request.Test do
  use ExUnit.Case

  setup_all do
    {:ok, _} = :application.ensure_all_started(:httparrot)
    :ok
  end

  test "makes several requests in parallel" do
    {_, _, body1} = url("/get") |> Etude.Request.get()
    req1 = url("/post") |> Etude.Request.post(body1)
    req2 = url("/put") |> Etude.Request.put(body1)

    {{{200, _, bp1}, {200, _, bp2}}, _} = Etude.resolve({req1, req2}, %Etude.State{mailbox: self()})
    {{{200, _, bl1}, {200, _, bl2}}, _} = Etude.resolve({req1, req2}, %Etude.State{mailbox: []})

    assert to_string(bp1) == to_string(bl1)
    assert to_string(bp2) == to_string(bl2)
  end

  defp url(path) do
    {:ok, port} = Application.fetch_env(:httparrot, :http_port)
    "http://localhost:#{port}#{path}"
  end
end
