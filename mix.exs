defmodule Etude.Request.Mixfile do
  use Mix.Project

  def project do
    [app: :etude_request,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [
      :logger,
      :hackney
    ]]
  end

  defp deps do
    [{ :etude, "~> 1.0.0-beta.0" },
     { :httparrot, "~> 0.3.4", only: :test },
     { :hackney, "~> 1.6.0" },
     { :mix_test_watch, "~> 0.2", only: :dev },]
  end
end
