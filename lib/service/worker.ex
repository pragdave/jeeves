defmodule Service.Worker do

  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_) do
    IO.puts "init worker"
    { :ok, %{} }
  end

  def handle_call(data, _from, state) do
    IO.inspect [ data, state ]
    { result, state } = if state[data] do
      result = state[data]
      IO.puts "Cached: #{result}"
      { result, state }
    else
      :timer.sleep(1000)
      result = data * data
      IO.puts "Worker calculates: #{data} * #{data} = #{result}"
      { result, Map.put(state, data, result) }
    end
    IO.inspect [ result, state ]
    {:reply, [result], state }
  end
  
  def square(pid, value) do
    :gen_server.call(pid, value)
  end
  
end

