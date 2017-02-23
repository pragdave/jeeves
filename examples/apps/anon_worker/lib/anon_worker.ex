defmodule KVStore do

  use Service.Anonymous, state: %{}, show_code: true

  def put(store, key, value) do
    set_state(Map.put(store, key, value)) do
      value
    end
  end
  
  def get(store, key) do
    store[key]
  end

end
