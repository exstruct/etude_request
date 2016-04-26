# Etude.Request

Parallel HTTP requests for [etude](https://github.com/camshaft/etude)

## Installation

`Etude.Request` is [available in Hex](https://hex.pm/docs/publish) and can be installed as:

  1. Add etude_request to your list of dependencies in `mix.exs`:

        def deps do
          [{:etude_request, "~> 0.0.1"}]
        end

  2. Ensure etude_request is started before your application:

        def application do
          [applications: [:etude_request]]
        end

## Usage

```elixir
{gh_status, gh_headers, gh_body} = Etude.Request.get("https://api.github.com")

IO.inspect {gh_status, gh_headers, gh_body}
# {%Etude.Request.Status{request: #Function<...>},
#  %Etude.Request.Headers{request: #Function<...>},
#  %Etude.Request.Body{request: #Function<...>}}

{ip_status, ip_headers, ip_body} = Etude.Request.get("https://api.ipify.org")

IO.inspect Etude.resolve([{gh_status, gh_headers}, {ip_status, ip_body}])
# [{200, [{"Server", "GitHub.com"}, ...]},
#  {200, "123.456.789.0"}]
```

## API

The options and functions should mostly be compatible with [httpoison](https://github.com/edgurgel/httpoison). One big exception is all functions in `Etude.Request` raise errors instead of return `{:ok, value} | {:error, reason}`, since error checking is done at request time instead of call time.
