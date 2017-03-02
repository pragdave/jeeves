defmodule T1 do
  use Jeeves.Anonymous, state: 99
  
  def api1(state, p1) do
    state + p1
  end

  def api2(state, p1) do
    set_state(state + p1) do
      state
    end
  end

  def get_state(state), do: state
end

defmodule AnonymousTest do
  use ExUnit.Case
  
  test "Top level module looks right" do
    info = T1.module_info()
    assert info[:attributes][:behaviour] == [GenServer]
    assert Enum.member?(info[:exports], { :api1, 2 })
    assert Enum.member?(info[:exports], { :run,  0 })
    assert Enum.member?(info[:exports], { :run,  1 })
  end
  
  test "Implementation module looks right" do
    info = T1.Implementation.module_info()
    assert Enum.member?(info[:exports], { :api1, 2 })    
  end

  test "Running the module starts a GenServer" do
    handle = T1.run()
    assert is_pid(handle)
  end

  test "The initial state is set" do
    handle = T1.run()
    assert T1.get_state(handle) == 99
  end
  
  test "The GenServer delegates to the implementation" do
    handle = T1.run()
    assert T1.api1(handle, 2) == 101
    assert T1.api1(handle, 3) == 102
  end

  test "The GenServer maintains state" do
    handle = T1.run()
    assert T1.api2(handle, 1)   == 99
    assert T1.get_state(handle) == 100
    assert T1.api2(handle, 1)   == 100
    assert T1.get_state(handle) == 101
  end
  
end

