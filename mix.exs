defmodule Service.Mixfile do
  use Mix.Project

  def project do
    [app: :service,
     version: "0.1.0",
     elixir: "~> 1.5-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      extra_applications: [:logger, :poolboy],
      mod: {Service.Application, []}
    ]
  end

  defp deps do
    [
      { :poolboy, "~> 1.5.0" }
    ]
  end
end
