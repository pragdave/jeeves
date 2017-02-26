defmodule Service.Common do

  alias Service.Util.PreprocessorState
  
  # state that we store as we're building the module
  
  @doc """
  We replace the regular def with something that records the definition in
  a list. No code is emitted here—that happens in the before_compile hook
  """
  
  defmacro def(call, body), do: def_implementation(call, body)

  # so I can test
  def def_implementation(call, body) do
    PreprocessorState.add_function({ call, body })
    nil
  end
  
  @doc """
  Used at the end of a service function to indicate that
  the state should be updated, and to provide a return value. The
  new state is passed as a parameter, and a `do` block is
  evaluated to provide the return value.

  If not called in a service function, then the return value of the
  function will be the value returned to the client, and the state
  will not be updated.

      def put(store, key, value) do
        set_state(Map.put(store, key, value)) do
          value
        end
      end
  
  """
  defmacro set_state(new_state, do: return) do
    quote do
      { :reply, unquote(return), unquote(new_state) }
    end
  end

  
  # The strategy is the module (Anonymous, Named, Pooled)

  @doc false
  def generate_common_code(strategy, opts, name) do
    PreprocessorState.start_link(opts)
    
    state = Keyword.get(opts, :state, :no_state)
    server_opts = if name do [ name: name ] else [ ] end
    
    quote do
      import Kernel,            except: [ def: 2 ]
      import Service.Common,    only:   [ def: 2, set_state: 2 ]

      @before_compile { unquote(strategy), :generate_code_callback }

      def run() do
        run(unquote(state))
      end
      
      def run(state) do
        # state = initial_state(state_override, unquote(state))
        { :ok, pid } = GenServer.start_link(__MODULE__, state, server_opts())
        pid
      end

      def init(state) do
        { :ok, state }
      end
      
      def initial_state(default_state, _your_state) do
        default_state
      end

      def server_opts() do
        unquote(server_opts)
      end

      defoverridable [ initial_state: 2 ]
    end
    |> maybe_show_generated_code(opts)
  end

  @doc false
  def generate_code(strategy) do
    
    { options, apis, handlers, implementations, _delegators } =
      create_functions_from_originals(strategy)
    
    PreprocessorState.stop()
    
    quote do
      use GenServer
      
      unquote_splicing(apis)
      unquote_splicing(handlers)
      defmodule Implementation do
        unquote_splicing(implementations)
      end
    end
    |> maybe_show_generated_code(options)
  end

  @doc false
  def create_functions_from_originals(strategy) do
    options = PreprocessorState.options()
    
    PreprocessorState.function_list
    |> Enum.reduce({nil, [], [], [], []}, &generate_functions(strategy, options, &1, &2))
  end


  @doc !"public only for testing"
  def generate_functions(
    strategy,
    options,
    original_fn,
    {_, apis, handlers, impls, delegators}
  )
    do
    {
      options,
      [ strategy.generate_api_call(options, original_fn)       | apis       ],
      [ strategy.generate_handle_call(options, original_fn)    | handlers   ],
      [ strategy.generate_implementation(options, original_fn) | impls      ],
      [ strategy.generate_delegator(options, original_fn)      | delegators ]
    }
  end

    
  @doc !"public only for testing"
  def create_genserver_response(response = {:reply, _, _}, _state) do
    response
  end

  @doc false
  def create_genserver_response(response, state) do
    { :reply, response, state }
  end
  
  @doc false
  def maybe_show_generated_code(code, opts) do
    if opts[:show_code] do
      IO.puts ""
      code
      |> Macro.to_string()
      |> String.replace(~r{^\w*\(}, "")
      |> String.replace(~r{\)\w*$}, "")
      |> String.replace(~r{def\((.*?)\)\)}, "def \\1)")
      |> IO.puts 
    end
    code
  end
end
