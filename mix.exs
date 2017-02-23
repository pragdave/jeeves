defmodule Service.Mixfile do
  use Mix.Project

  @version "0.1.0"

  @deps [
    { :poolboy, "~> 1.5.0" },
    { :ex_doc,  "~> 0.14", only: :dev, runtime: false }
  ]

  
  # ------------------------------------------------------------

  @in_production Mix.env == :prod
  
  def project do
    [
      app:     :service,
      version: @version,
      elixir:  "~> 1.5-dev",
      deps:    @deps,
      build_embedded:  @in_production,
      start_permanent: @in_production,

      # Docs
      name: "Service",
      source_url: "https://github.com/pragdave/service",
      homepage_url: "https://github.com/pragdave/service",
      docs: [
        main:   "README", 
#        logo:   "path/to/logo.png",
        extras: [ "README.md", "background.md", "LICENSE.md" ],
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger ],
    ]
  end

end
