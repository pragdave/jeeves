# Pooled Named Worker

    $ iex -S mix
    iex(1)> PooledNamedWorker.run
    [worker_module: PooledNamedWorker.Worker, pool_opts: [min: 1, max: 4],
     name: Vince, state: %{a: 1}]
    [worker_module: PooledNamedWorker.Worker, pool_opts: [min: 1, max: 4],
     name: Vince, state: %{a: 1}]
    [name: {:local, Vince}, worker_module: PooledNamedWorker.Worker, size: 1,
     max_overflow: 3]
    {:ok, #PID<0.214.0>}

    iex(2)> PooledNamedWorker.process
    in pool worker #PID<0.217.0> %{a: 1}
    "#PID<0.217.0> done"

    iex(3)> PooledNamedWorker.process
    in pool worker #PID<0.217.0> %{a: 2}
    "#PID<0.217.0> done"

    iex(4)> PooledNamedWorker.process
    in pool worker #PID<0.217.0> %{a: 3}
    "#PID<0.217.0> done"
