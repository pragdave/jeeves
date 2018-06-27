defmodule PooledNamedWorker.Mixfile do
  use Mix.Project

  @name    :pooled_named_worker
  @version "0.1.0"
  @deps [
    jeeves: [ path: "../../.." ]
  ]

  ##################################################
  
  def project do
    [
      app:         @name,
      version:     @version,
      deps:        @deps,
      build_path:  "../../_build",
      config_path: "../../config/config.exs",
      deps_path:   "../../deps",
      lockfile:    "../../mix.lock",
      elixir:      "~> 1.5-dev",
    ]
  end

  def application do
    [
#      extra_applications: [:logger, :poolboy]
    ]
  end

end
