defmodule N1 do
  use Jeeves.Named, state: 99, name: Fred
  
  def api1(p1) do
    state + p1
  end

  def api2(p1) do
    set_state(state + p1) do
      state
    end
  end

  def get_state(), do: state
end

defmodule NamedTest do
  use ExUnit.Case, async: true

  def stop_if_running do
    case Process.whereis(N1) do
      nil -> nil
      pid -> GenServer.stop(pid)
    end
  end
  
  setup do
    stop_if_running()
    on_exit fn ->
      stop_if_running()
    end
      
  end
  
  test "Top level module looks right" do
    info = N1.module_info()
    assert info[:attributes][:behaviour] == [GenServer]
    assert Enum.member?(info[:exports], { :api1, 1 })
    assert Enum.member?(info[:exports], { :run,  0 })
    assert Enum.member?(info[:exports], { :run,  1 })
  end
  
  test "Implementation module looks right" do
    info = N1.Implementation.module_info()
    assert Enum.member?(info[:exports], { :api1, 2 })    
  end

  test "Running the module starts a GenServer" do
    handle = N1.run()
    assert is_pid(handle)
  end

  test "The initial state is set" do
    N1.run()
    assert N1.get_state() == 99
  end
  
  test "The GenServer delegates to the implementation" do
    N1.run()
    assert N1.api1(2) == 101
    assert N1.api1(3) == 102
  end

  test "The GenServer maintains state" do
    N1.run()
    assert N1.api2(1)   == 99
    assert N1.get_state() == 100
    assert N1.api2(1)   == 100
    assert N1.get_state() == 101
  end
  
end

