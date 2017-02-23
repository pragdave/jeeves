defmodule Service.Pooled do

  alias Service.Util.PreprocessorState

  defmacro __using__(opts \\ []) do
    generate_pooled_service(opts)
  end
  
  def generate_pooled_service(opts) do
    name  = Keyword.get(opts, :service_name, :no_name)
    state = Keyword.get(opts, :state,        :no_state)

    PreprocessorState.start_link(opts)
    
    quote do
      import Kernel,            except: [ def: 2 ]
      import Service.Common,    only:   [ def: 2, set_state: 2 ]
      
      @before_compile { unquote(__MODULE__), :generate_code }
      
      @name unquote(name)

      def run() do
        run(unquote(state))
      end
            
      def run(state) do
        Service.Scheduler.start_new_pool(worker_module: __MODULE__.Worker,
          pool_opts: unquote(opts[:pool] || [ min: 2, max: 5]),
          name: @name,
          state: state)
      end
    end
    |> Service.Common.maybe_show_generated_code(opts)
  end

  defmacro generate_code(_) do

    { options, apis, handlers, implementations, delegators } =
      Service.Common.create_functions_from_originals(__MODULE__)
    
    PreprocessorState.stop()
    
    quote do
      
      unquote_splicing(delegators)
      
      defmodule Worker do
        use GenServer

        def start_link(args) do
          GenServer.start_link(__MODULE__, args)
        end
        
        unquote_splicing(apis)
        unquote_splicing(handlers)
        defmodule Implementation do
          unquote_splicing(implementations)
        end
        
      end
    end
    |> Service.Common.maybe_show_generated_code(options)
  end


  defdelegate generate_api_call(options,function),       to: Service.Named
  defdelegate generate_handle_call(options,function),    to: Service.Named
  defdelegate generate_implementation(options,function), to: Service.Named
  
  def generate_delegator(_options, {call, _body}) do
    quote do
      def unquote(call), do: unquote(delegate_body(call))
    end
  end

  def delegate_body(call) do
    request = Service.Named.call_signature(call)
    quote do
      Service.Scheduler.run(@name, unquote(request))
    end
  end
  
end
