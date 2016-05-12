defmodule Etude.Request do
  use Etude.Request.Base
  alias Etude.Request.Error
  alias Etude.Request.Response.{Status, Headers, Body}

  def __request__(request, req_id, state) do
    case Map.fetch(state.private, {__MODULE__, req_id}) do
      :error ->
        case Etude.Thunk.resolve_recursive(request, state) do
          {:await, thunk, state} ->
            {:await, &__request__(thunk, req_id, &1), state}
          {request, state} ->
            execute_request(request, req_id, state)
        end
      {:ok, id} ->
        {id, state}
    end
  end

  defp execute_request(request, req_id, state) do
    %{method: method, url: url, headers: headers, body: body, options: options} = request

    options = build_hackney_options(options, state.mailbox)

    case :hackney.request(method, url, headers, body, options) do
      {:ok, id} ->
        state = state
        |> add_receivers(id, url)
        |> Etude.State.put_private({__MODULE__, req_id}, id)
        {id, state}
      {:ok, status, headers} ->
        handle_sync(status, headers, "", req_id, state)
      {:ok, status, headers, client} ->
        case :hackney.body(client) do
          {:ok, body} ->
            handle_sync(status, headers, body, req_id, state)
          {:error, reason} ->
            error = %Error{reason: reason, url: url}
            handle_sync(error, error, error, req_id, state)
        end
      {:error, reason} ->
        error = %Error{reason: reason, url: url}
        handle_sync(error, error, error, req_id, state)
    end
  end

  defp handle_sync(status, headers, body, req_id, state) do
    id = :erlang.make_ref()
    private = Map.merge(state.private, %{{__MODULE__, req_id} => id,
                                         {Status, id} => status,
                                         {Headers, id} => headers,
                                         {Body, id} => body})
    state = %{state | private: private}
    {id, state}
  end

  defp add_receivers(state, id, url) do
    state
    |> Etude.State.add_receiver(fn
      # Handle the status code message
      ({:hackney_response, ^id, {:status, code, _reason}}, state) ->
        Etude.State.put_private(state, {Status, id}, code)

      # Handle the headers message
      ({:hackney_response, ^id, {:headers, headers}}, state) ->
        Etude.State.put_private(state, {Headers, id}, headers)

      # The stream is done; clean things up
      ({:hackney_response, ^id, :done}, state) ->
        private = state.private
        body = private |> Map.get({__MODULE__.Chunks, id}, []) |> :lists.reverse()
        private = private
        |> Map.put({Body, id}, body)
        |> Map.delete({__MODULE__.Chunks, id})
        {:done, %{state | private: private}}

      # Handle error messages
      ({:hackney_response, ^id, {:error, reason}}, state) ->
        error = %Error{reason: reason, url: url}
        {:done, put_error(state, id, error)}

      # Handle body chunks
      ({:hackney_response, ^id, chunk}, state) when is_binary(chunk) ->
        key = {__MODULE__.Chunks, id}
        private = state.private
        chunks = Map.get(private, key, [])
        %{state | private: Map.put(private, key, [chunk | chunks])}

      # Ignore the redirect messages - we don't care
      ({:hackney_response, ^id, {:redirect, _to, _headers}}, state) ->
        state

      (_, _) ->
        nil
    end)
  end

  defp put_error(state, id, error) do
    %{state | private: Map.merge(state.private, %{
             {Status, id} => error,
             {Headers, id} => error,
             {Body, id} => error})}
  end

  defp build_hackney_options(options, mailbox) do
    timeout = options[:timeout]
    recv_timeout = options[:recv_timeout]
    proxy = options[:proxy]
    proxy_auth = options[:proxy_auth]
    ssl = options[:ssl]
    follow_redirect = options[:follow_redirect]
    max_redirect = options[:max_redirect]

    hn_options = options[:hackney] || []

    if timeout, do: hn_options = [{:connect_timeout, timeout} | hn_options]
    if recv_timeout, do: hn_options = [{:recv_timeout, recv_timeout} | hn_options]
    if proxy, do: hn_options = [{:proxy, proxy} | hn_options]
    if proxy_auth, do: hn_options = [{:proxy_auth, proxy_auth} | hn_options]
    if ssl, do: hn_options = [{:ssl_options, ssl} | hn_options]
    if follow_redirect, do: hn_options = [{:follow_redirect, follow_redirect} | hn_options]
    if max_redirect, do: hn_options = [{:max_redirect, max_redirect} | hn_options]

    if is_pid(mailbox), do: hn_options = [:async, {:stream_to, mailbox} | hn_options]

    hn_options
  end
end
