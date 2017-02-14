defmodule Service.Application do

  @moduledoc false

  use Application

  @pool_name :my_pool
  
  @poolboy_config  [
      name:          {:local, @pool_name},
      worker_module: Service.Worker,
      size:          1,
      max_overflow:  1,
      strategy:      :fifo,
  ]

  
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(@pool_name, @poolboy_config, [])
    ]

    opts = [strategy: :one_for_one, name: Service.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def pool_square(x) do
    :poolboy.transaction(
     @pool_name,
      fn(pid) -> Service.Worker.square(pid, x) end,
      :infinity
    )
  end  
end
