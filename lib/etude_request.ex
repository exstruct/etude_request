defmodule Etude.Request do
  use Etude.Request.Base
  import Etude.Macros

  defmodule Error do
    defexception [:reason, :request]

    def message(%{reason: reason, request: %{url: url}}) do
      "Request to #{inspect(url)} failed with reason #{inspect(reason)}"
    end
  end

  defmodule Response do
    defstruct status_code: nil, body: nil, headers: []
    @type t :: %__MODULE__{status_code: integer, body: binary, headers: list}
  end

  deffuture future(req) do
    Etude.Request.__execute__(req, state)
  end

  def __execute__(request, state) do
    %{method: method, url: url, headers: headers, body: body, options: options} = request

    options = build_hackney_options(options)

    case :hackney.request(method, url, headers, body, options) do
      {:ok, id} ->
        add_receivers(state, id, request)
      {:error, reason} ->
        error = %Error{reason: reason, request: request}
        {:error, error, state}
    end
  end

  defp add_receivers(state, id, request) do
    receiver = %Etude.Receiver{
      handle_info: fn
        # Handle the status code message
        ({_, headers, body}, {:hackney_response, ^id, {:status, code, _reason}}, state) ->
          {:cont, {code, headers, body}, state}

        # Handle the headers message
        ({code, _, body}, {:hackney_response, ^id, {:headers, headers}}, state) ->
          {:cont, {code, headers, body}, state}

        # The stream is done; clean things up
        ({code, headers, body}, {:hackney_response, ^id, :done}, state) ->
          resp = %Response{status_code: code, headers: headers, body: :erlang.iolist_to_binary(body)}
          {:ok, resp, state}

        # Handle error messages
        (_, {:hackney_response, ^id, {:error, reason}}, state) ->
          error = %Error{reason: reason, request: request}
          {:error, error, state}

        # Handle body chunks
        ({code, headers, prev}, {:hackney_response, ^id, chunk}, state) ->
          {:cont, {code, headers, [prev, chunk]}, state}

        # Ignore the redirect messages - we don't care
        (resp, {:hackney_response, ^id, {:redirect, _to, _headers}}, state) ->
          {:cont, resp, state}

        (_, _, _) ->
          :pass
      end,
      cancel: fn(_, state) ->
        :hackney_manager.close_request(id)
        state
      end
    }

    {register, state} = Etude.State.create_receiver(state, receiver, {0, [], []})

    {:await, register, state}
  end

  defp build_hackney_options(options) do
    timeout = options[:timeout]
    recv_timeout = options[:recv_timeout]
    proxy = options[:proxy]
    proxy_auth = options[:proxy_auth]
    ssl = options[:ssl]
    follow_redirect = options[:follow_redirect]
    max_redirect = options[:max_redirect]

    hn_options = options[:hackney] || []

    [
      {timeout, {:connect_timeout, timeout}},
      {recv_timeout, {:recv_timeout, recv_timeout}},
      {proxy, {:proxy, proxy}},
      {proxy_auth, {:proxy_auth, proxy_auth}},
      {ssl, {:ssl_options, ssl}},
      {follow_redirect, {:follow_redirect, follow_redirect}},
      {max_redirect, {:max_redirect, max_redirect}},
      {true, [:async, {:stream_to, self()}]}
    ]
    |> Enum.reduce(hn_options, fn
      ({test, info}, acc) when is_list(info) ->
        if test do
          info ++ acc
        else
          acc
        end
      ({test, info}, acc) ->
        if test do
          [info | acc]
        else
          acc
        end
    end)
  end
end
