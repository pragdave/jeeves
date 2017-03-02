# Named Worker

    $ iex -S mix
    iex(1)> NamedKVStore.run %{name: "Dave"}
    #PID<0.186.0>

    iex(2)> NamedKVStore.put :born, "UK"
    "UK"

    iex(3)> NamedKVStore.get :name
    "Dave"
    
    iex(4)> NamedKVStore.get :born
    "UK"

