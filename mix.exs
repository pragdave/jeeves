defmodule Jeeves.Mixfile do
  use Mix.Project

  @version "0.1.0"

  @deps [
    { :poolboy, "~> 1.5.0" },
    { :ex_doc,  "~> 0.14", only: :dev, runtime: false }
  ]

  @description """
  Jeeves is library that transforms regular modules into named or anonymous
  singleton or pooled GenServers. Just write your business functions, and Jeeves
  will convert them into an API, a server, and potentially a pooled set of workers.
  """
  
  
  # ------------------------------------------------------------

  
  def project do
    in_production = Mix.env == :prod
    [
      app:     :jeeves,
      version: @version,
      elixir:  "~> 1.5-dev",
      deps:    @deps,
      package: package(),
      description:     @description,
      build_embedded:  in_production,
      start_permanent: in_production,

      # Docs
      name: "Jeeves",
      source_url: "https://github.com/pragdave/jeeves",
      homepage_url: "https://github.com/pragdave/jeeves",
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

  defp package do
    [
      files: [
        "lib", "mix.exs", "README.md", "LICENSE.md"
      ],
      maintainers: [
        "Dave Thomas <dave@pragdave.me>"
      ],
      licenses: [
        "Apache 2 (see the file LICENSE.md for details)"
      ],
      links: %{
        "GitHub" => "https://github.com/pragdave/jeeves",
      }
    ]
  end  
  
  
end
