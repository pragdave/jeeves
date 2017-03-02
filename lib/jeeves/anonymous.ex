defmodule Jeeves.Anonymous do

  @moduledoc """
  Implement an anonymous service.

  ### Usage

  To create the service:

  * Create a module that implements the API you want. This API will be
    expressed as a set of public functions. Each function will be
    defined to accept the current state as its first parameter. If a
    function wants to change the state, it must end with a call to the
    `Jeeves.Common.update_state/2` function (which will have been
    imported into your module automatically).

    For this example, we'll call the module `MyService`.

  * Add the line `use Jeeves.Anonymous` to the top of this module.

  To consume the service:

  * Create an instance of the service with `MyJeeves.run()`. You can pass 
    initial state to the service as an optional parameter. This call returns
    a handle to this service instance.

  * Call the API functions in the service, using the handle as a first parameter.


  ### Example

      defmodule Accumulator do
        using Jeeves.Anonymous, state: 0

        def current_value(acc), do: acc
        def increment(acc, by \\ 1) do
          update_state(acc + by)
        end
      end
  
      with acc = Accumulator.run(10) do
        Accumulator.increment(acc, 3)      
        Accumulator.increment(acc, 2)
        Accumulator.current_value(acc)   # => 15
      end


  ### Options

  You can pass a keyword list to `use Jeeves.Anonymous:`

  * `state:` _value_

    Set the detail initial state of the service to `value`. This can be 
    overridden by passing a different value to the `run` function.

  * `showcode:` _boolean_

    If truthy, dump a representation of the generated code to STDOUT during
    compilation.

  """

  @doc false
  defmacro __using__(opts \\ []) do
    Jeeves.Common.generate_common_code(
      __CALLER__.module,
      __MODULE__,
      opts,
      _name = nil)
  end

  @doc false
  defmacro generate_code_callback(_) do
    Jeeves.Common.generate_code(__CALLER__.module, __MODULE__)
  end
  
  @doc false
  def generate_api_call(_options, {call, _body}) do
    quote do
      def(unquote(call), do: unquote(api_body(call)))
    end
  end

  @doc false
  defp api_body(call) do
    { server, request } = call_signature(call)
    quote do
      GenServer.call(unquote(var!(server)), unquote(request))
    end
  end
  
  @doc false
  def generate_handle_call(_options, {call, _body}) do
    { state, request } = call_signature(call)
    quote do
      def handle_call(unquote(request), _, unquote(var!(state))) do
        __MODULE__.Implementation.unquote(call)
        |> Jeeves.Common.create_genserver_response(unquote(var!(state)))
      end
    end
  end

  @doc false
  def generate_implementation(_options, {call, body}) do
    quote do
      def(unquote(call), unquote(body))
    end
  end

  
  @doc !"only used for pools"
  def generate_delegator(_options, {_call, _body}), do: nil
  
  # given def fred(store, a, b) return { store, { :fred, a, b }}
  @doc false
  def call_signature({ name, _, [ server | args ] }) do
    {
      var!(server),
      { :{}, [], [ name |  Enum.map(args, fn a -> var!(a) end) ] }
    }
  end
  
end
