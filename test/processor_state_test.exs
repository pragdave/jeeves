defmodule ProcessorStateTest do
  use ExUnit.Case

  alias Service.Util.PreprocessorState, as: PS

  @some_options %{ name: "Vince", status: "playa" }

  @name PS.name
  
  test "can be started and stopped" do
    assert Process.whereis(@name) == nil
    PS.start_link(@some_options)
    assert is_pid(Process.whereis(@name))
    PS.stop()
    assert Process.whereis(@name) == nil
  end
    
  describe "Once started" do

    setup do
      PS.start_link(@some_options)  # linked to test process, so no need to stop
      :ok
    end

    test "maintains initial options" do
      assert PS.options() == @some_options
    end
    
    test "maintains starts with no functions" do
      assert PS.function_list() == []
    end

    test "records functions" do
      PS.add_function(:one)
      PS.add_function(:two)
      assert PS.function_list() == [ :two, :one ]
    end
  end
end
