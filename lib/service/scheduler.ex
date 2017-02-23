defmodule Service.Scheduler do

@moduledoc """

This is the runtime support for pooled worked. At compile time,
code such as this:


is turned into this:

    defmodule TestNamedWorker do
      @name :vince

      def run() do
        Service.Scheduler.start_new_pool(worker_module: __MODULE__.Worker,
          pool_opts: [ mix: 2, max: 3 ],
          name: @name)
      end

      def process() do
        Service.Scheduler.run(@name, {:process})
      end

      defmodule Worker do
        use GenServer

        def start_link(args) do
          GenServer.start_link(__MODULE__, args)
        end

        def init(args) do
          { :ok,args }
        end

        def handle_call({:process}, _, state) do
          __MODULE__.Implementation.process(state)
        end

        defmodule Implementation do
          def process(state) do
            # ...
            {:reply, self(), state}
          end
        end
      end
    end

Each original module that specifies a pool arg will be associated with
its own pool, and that pool is run by the scheduler code below.

"""

  


  defdelegate start_new_pool(args),
    to: Service.Scheduler.PoolSupervisor,
    as: :start_link
  
  def run(pool, what_to_run) do
    IO.puts "scheduler run #{inspect what_to_run}"
    :poolboy.transaction(pool, fn pid ->
      IO.puts "genserver.call #{inspect pid}, #{inspect what_to_run}"
      GenServer.call(pid, what_to_run)
    end)
  end
  
end

