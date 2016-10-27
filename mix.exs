defmodule Etude.Request.Mixfile do
  use Mix.Project

  def project do
    [app: :etude_request,
     version: "0.2.0",
     elixir: "~> 1.2",
     description: "Parallel HTTP requests for etude",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package]
  end

  def application do
    [applications: [
      :logger,
      :hackney
    ]]
  end

  defp deps do
    [{:etude, "~> 1.0.0"},
     {:httparrot, "~> 0.4.0", only: :test},
     {:hackney, "~> 1.6.0"},
     {:poison, "~> 2.2.0", only: :test},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/exstruct/etude_request"}]
  end
end
