defmodule Jeeves.Service do

  @moduledoc """
  Implement a service consisting of a pool of workers, all running in
  their own application.


  ### Prerequisites

  You'll need to add poolboy to your project dependencies.

  ### Usage

  To create the service:

  * Create a module that implements the API you want. This API will be
    expressed as a set of public functions. Each function will automatically
    receive the current state in a variable (by default named `state`). There is
    no need to declare this as a parameter.[<small>why?</small>](#why-magic-state).
    If a function wants to change the state, it must end with a call to the
    `Jeeves.Common.update_state/2` function (which will have been
    imported into your module automatically).

  * Add the line `use Jeeves.Service` to the top of this module.

  ### Options

  You can pass a keyword list to `use Jeeves.Service:`

  * `state_name:` _atom_

    The default name for the state variable is (unimaginatively)  `state`. 
    Use `state_name` to override this. For example, the previous 
    example named the state `options`, and inside the `recognize` function
    your could write `options.algorithm` to look up the algorithm to use.

  * `pool: [ ` _options_ ` ]`

    Set options for the service pool. One or more of:

    * `min: n`

      The minimum number of workers that should be active, and by extension 
      the number of workers started when the pool is run. Default is 2.

    * `max: n`

      The maximum number of workers. If all workers are busy and a new request
      arrives, a new worker will be started to handle it if the current worker
      count is less than `max`. Excess idle workers will be quietly killed off
      in the background. Default value is `(min+1)*2`.

  * `showcode:` _boolean_

    If truthy, dump a representation of the generated code to STDOUT during
    compilation.

  * `timeout:` integer or float
    
    Specify the timeout to be used when the client calls workers in the pool.
    If all workers are busy, and none becomes free in that time, an OTP
    exception is raised. An integer specifies the timeout in milliseconds, and
    a float in seconds (so 1.5 is the same as 1500).


  ## Consuming the Service

  Each service runs in an independent application. These applications
  are referenced by the main application. 

  The main application lists the services it uses in its `mix.exs`
  file.

  «todo: finish this»

  ### State

  Each worker has independent state. This state is initialized in two stages.

  First, the main application maintains a list of services it uses in its 
  `mix.exs` file:


      @services [
        prime_factors: [ 
          args: [ max_calc_time: 10_000 ]
        ]
      ]

  When the main application starts, it starts each service application in turn. 
  As each starts, it passes the arguments in the `args` list to the function
  `setup_worker_state` in the service. This function does what is required to
  create a state that can be passed to each worker when it is started.

  For example, our PrimeFactors service might want to maintain a cache
  of previously calculated results, shared between all the workers. It
  could dothis by creating an agent in the
  `setup_worker_state`function and adding its pid to the state it
  returns.

      def setup_worker_state(initial_state) do
         { :ok, pid } = Agent.start_link(fn -> %{} end)
         initial_state
         |> Enum.info(%{ cache: pid })
      end

  Each worker would be able to access that agent via the state it
  receives:

      def factor(n) do
        # yes, two workers could calculate the same value in parallel... :)

        case Agent.get(state.cache, fn map -> map[n] end) do

        nil ->
          result = complex_calculation(n)
          Agent.update(state.cache, fn map -> Map.put(map, n, result) end)
          result

        result ->
          result
        end
      end
  

  """

  
  alias Jeeves.Util.PreprocessorState, as: PS

  @doc false
  defmacro __using__(opts \\ []) do
    generate_application_service(__CALLER__.module, opts)
  end
  
  @doc false
  def generate_application_service(caller, opts) do
    name  = Keyword.get(opts, :service_name, nil)
    state = Keyword.get(opts, :state,        :no_state)

    PS.start_link(caller, opts)
    
    quote do
      import Kernel,           except: [ def: 2 ]
      import Jeeves.Common,    only:   [ def: 2, set_state: 1, set_state: 2 ]
      use    Application
      
      @before_compile { unquote(__MODULE__), :generate_code }
      
      @name unquote(name) || Module.concat( __MODULE__, PoolSupervisor)

      def start(_, _) do
        { :ok, self() }
      end
      
      def run() do
        run(unquote(state))
      end
            
      def run(state) do
        Jeeves.Scheduler.start_new_pool(worker_module: __MODULE__.Worker,
          pool_opts: unquote(opts[:pool] || [ min: 1, max: 4]),
          name: @name,
          state: setup_worker_state(state))
      end

      def setup_worker_state(initial_state), do: initial_state

      defoverridable setup_worker_state: 1
      
    end
    |> Jeeves.Common.maybe_show_generated_code(opts)
  end

  @doc false
  defmacro generate_code(_) do

    { options, apis, handlers, implementations, delegators } =
      Jeeves.Common.create_functions_from_originals(__CALLER__.module, __MODULE__)
    
    PS.stop(__CALLER__.module)
    
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
    |> Jeeves.Common.maybe_show_generated_code(options)
  end

  @doc false
  defdelegate generate_api_call(options,function),       to: Jeeves.Named
  @doc false
  defdelegate generate_handle_call(options,function),    to: Jeeves.Named
  @doc false
  defdelegate generate_implementation(options,function), to: Jeeves.Named
  
  @doc false
  def generate_delegator(options, {call, _body}) do
    quote do
      def unquote(call), do: unquote(delegate_body(options, call))
    end
  end

  @doc false
  def delegate_body(options, call) do
    timeout = options[:timeout] || 5000
    request = Jeeves.Named.call_signature(call)
    quote do
      Jeeves.Scheduler.run(@name, unquote(request), unquote(timeout))
    end
  end
  
end
