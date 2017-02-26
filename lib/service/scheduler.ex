defmodule Service.Scheduler do

@moduledoc """

This is the runtime support for pooled worked. At compile time,
code such as this:

Each original module that specifies a pool arg will be associated with
its own pool, and that pool is run by the scheduler code below.

"""


  defdelegate start_new_pool(args),
    to: Service.Scheduler.PoolSupervisor,
    as: :start_link
  
  def run(pool, what_to_run) do
    :poolboy.transaction(pool, fn pid ->
      GenServer.call(pid, what_to_run)
    end)
  end
  
end

