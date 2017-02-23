defmodule NamedWorkerTest do
  use ExUnit.Case

  alias NamedKVStore, as: KV
  alias NamedKVStore.Implementation, as: KVI
  
  test "the implementation works" do
    state = %{ name: "test" }

    assert KVI.get(state, :name) == "test"
    assert KVI.put(state, :name, "case") ==  {:reply, "case", %{name: "case"}}
  end

  test "the worker runs" do
    KV.run()
    KV.put(:name, :test)
    assert KV.get(:name) == :test
  end

  test "initializing via run()" do
    KV.run(%{ name: :initialized })
    assert KV.get(:name) == :initialized
  end

  test "service name is correct" do
    assert Process.whereis(:alfred) == nil
    KV.run
    assert is_pid(Process.whereis(:alfred))
  end
  
end
