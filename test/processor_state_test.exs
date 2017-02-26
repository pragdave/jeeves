defmodule ProcessorStateTest do
  use ExUnit.Case

  alias Service.Util.PreprocessorState, as: PS

  @some_options %{ name: "Vince", status: "playa" }

  @name PS.name_for(__MODULE__)
  
  test "can be started and stopped" do
    assert Process.whereis(@name) == nil
    PS.start_link(__MODULE__, @some_options)
    assert is_pid(Process.whereis(@name))
    PS.stop(__MODULE__)
    assert Process.whereis(@name) == nil
  end
    
  describe "Once started" do

    setup do
      PS.start_link(__MODULE__, @some_options)  # linked to test process, so no need to stop
      :ok
    end

    test "maintains initial options" do
      assert PS.options(__MODULE__) == @some_options
    end
    
    test "maintains starts with no functions" do
      assert PS.function_list(__MODULE__) == []
    end

    test "records functions" do
      PS.add_function(__MODULE__, :one)
      PS.add_function(__MODULE__, :two)
      assert PS.function_list(__MODULE__) == [ :two, :one ]
    end
  end
end
