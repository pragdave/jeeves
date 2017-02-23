defmodule Examples.Mixfile do
  use Mix.Project

  @deps [
    service: [ path: ".." ]
  ]

  ##################################################

  @in_production Mix.env == :prod
  
  def project do
    [
      apps_path:       "apps",
      build_embedded:  @in_production,
      start_permanent: @in_production,
      deps:            @deps
    ]
  end
end
