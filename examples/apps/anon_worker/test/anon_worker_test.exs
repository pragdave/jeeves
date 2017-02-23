defmodule AnonWorkerTest do
  use ExUnit.Case

  test "the implementation works" do
    state = %{ name: "test" }

    assert KVStore.Implementation.get(state, :name) == "test"
    assert KVStore.Implementation.put(state, :name, "case") ==  {:reply, "case", %{name: "case"}}
  
  end

  test "the worker runs" do
    kv = KVStore.run()
    assert is_pid(kv)
    KVStore.put(kv, :name, :test)
    assert KVStore.get(kv, :name) == :test
  end

  test "initializing via run()" do
    kv = KVStore.run(%{ name: :initialized })
    assert is_pid(kv)
    assert KVStore.get(kv, :name) == :initialized
  end

end
