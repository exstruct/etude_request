# etude_request

Parallel HTTP requests for [etude](https://github.com/exstruct/etude)

## Installation

`Etude.Request` is [available in Hex](https://hex.pm/docs/publish) and can be installed as:

  1. Add etude_request to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:etude_request, "~> 0.1.0"}]
  end
  ```

  2. Ensure etude_request is started before your application:

  ```elixir
  def application do
    [applications: [:etude_request]]
  end
  ```

## Usage

```elixir
github = Etude.Request.get("https://api.github.com")

ip = Etude.Request.get("https://api.ipify.org")

Etude.join([github, ip]) |> Etude.fork!()
# [%Etude.Request.Response{status_code: 200, headers: [...], body: ...},
#  %Etude.Request.Response{...}]
```

## API

The options and functions should mostly be compatible with [httpoison](https://github.com/edgurgel/httpoison).
