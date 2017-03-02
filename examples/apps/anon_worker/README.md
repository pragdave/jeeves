# AnonWorker


    $ iex -S mix 

    iex> handle = KVStore.run language: "elixir"
    #PID<>
    
    iex> KVStore.put handle, :name, "josé"
    "josé"
    
    iex> KVStore.get handle, :name
    "josé"
    
    iex> KVStore.get handle, :language
    "elixir"
    
    
