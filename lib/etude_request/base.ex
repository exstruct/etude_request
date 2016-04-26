defmodule Etude.Request.Base do
  defmacro __using__(_) do
    quote unquote: false do
      for method <- [:get, :head, :delete, :options] do
        def unquote(method)(url, headers \\ [], options \\ []) do
          request(unquote(method), url, "", headers, options)
        end
      end

      for method <- [:put, :post] do
        def unquote(method)(url, body \\ "", headers \\ [], options \\ []) do
          request(unquote(method), url, body, headers, options)
        end
      end

      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        request = %{method: method,
                    url: url,
                    body: body,
                    headers: headers,
                    options: options} # TODO add manipulation functions from the macro caller here

        req_id = :erlang.phash2(request)

        exec = &Etude.Request.__request__(request, req_id, &1)

        {%Etude.Request.Response.Status{request: exec},
         %Etude.Request.Response.Headers{request: exec},
         %Etude.Request.Response.Body{request: exec}}
      end
    end
  end
end
