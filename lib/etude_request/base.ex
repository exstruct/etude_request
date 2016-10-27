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

        Etude.Request.future(request)
      end
    end
  end
end
