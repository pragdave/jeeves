defmodule Service.Anonymous do

  @sa_functions :ets.new(:sa_functions, [ :duplicate_bag ])
  
  defmacro __using__(opts \\ []) do
    :ets.delete_all_objects(@sa_functions)

    state = Keyword.get(opts, :state, :no_state)
    
    result = quote do
      import Kernel,            except: [ def: 2 ]
      import Service.Anonymous, only:   [ def: 2, set_state: 2 ]

      @before_compile Service.Anonymous

      def run(state_override \\ nil) do
        state = initial_state(unquote(state), state_override)
        { :ok, pid } = GenServer.start_link(__MODULE__, state)
        pid
      end

      def initial_state(default_state, _your_state) do
        default_state
      end

      defoverridable [ initial_state: 2 ]
    end

    IO.puts Macro.to_string(result)
    result
  end

  defmacro __before_compile__(_env) do
    implementation()
  end

  defp implementation() do
    { apis, handlers, implementations } =
      :ets.foldl(&generate_functions/2, {[], [], []}, @sa_functions)
    result = quote do
      use GenServer
      
      unquote_splicing(apis)
      unquote_splicing(handlers)
      defmodule Implementation do
        unquote_splicing(implementations)
      end
    end
    IO.puts Macro.to_string(result)
    result
  end
  
  
  defmacro def(call, body) do
    func = { call, body }
    
    :ets.insert(@sa_functions, func)
    nil
  end


  defmacro set_state(new_state, do: return) do
    quote do
      { :reply, unquote(return), unquote(new_state) }
    end
  end

  defp generate_functions(original_fn, {apis, handlers, impls}) do
    {
      [ generate_api_call(original_fn)       | apis ],
      [ generate_handle_call(original_fn)    | handlers ],
      [ generate_implementation(original_fn) | impls ]
    }
  end

  defp generate_api_call({call, _body}) do
    result = quote do
      def(unquote(call), do: unquote(api_body(call)))
    end
    result
  end

  defp api_body(call) do
     { server, request } = call_signature(call)
    quote do
      GenServer.call(unquote(var!(server)), unquote(request))
    end
  end
  
  defp generate_handle_call({call, _body}) do
    { state, request } = call_signature(call)
    result = quote do
      def handle_call(unquote(request), _, unquote(var!(state))) do
        __MODULE__.Implementation.unquote(call)
        |> Service.Anonymous.create_genserver_response(unquote(var!(state)))
      end
    end
    result
  end

  def create_genserver_response(response = {:reply, _, _}, _state) do
    response
  end

  def create_genserver_response(response, state) do
    { :reply, response, state }
  end
  

  defp generate_implementation({call, body}) do
    quote do
      def(unquote(call), unquote(body))
    end
  end

  # given def fred(store, a, b) return { store, { :fred, a, b }}
  
  defp call_signature({ name, _, [ server | args ] }) do
    {
      var!(server),
      { :{}, [], [ name |  Enum.map(args, fn a -> var!(a) end) ] }
    }
  end
end


defmodule KVStore do

  use Service.Anonymous, state: %{}

  def put(store, key, value) do
    set_state(Map.put(store, key, value)) do
      value
    end
  end
  
  def get(store, key) do
    store[key]
  end

end
