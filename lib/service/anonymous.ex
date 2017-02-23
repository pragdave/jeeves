defmodule Service.Anonymous do

#  require Service.Common
  
  defmacro __using__(opts \\ []) do
    Service.Common.generate_common_code(__MODULE__, opts, _name = nil)
  end

  defmacro generate_code_callback(_) do
    Service.Common.generate_code(__MODULE__)
  end
  
  def generate_api_call(_options, {call, _body}) do
    quote do
      def(unquote(call), do: unquote(api_body(call)))
    end
  end

  defp api_body(call) do
    { server, request } = call_signature(call)
    quote do
      GenServer.call(unquote(var!(server)), unquote(request))
    end
  end
  
  def generate_handle_call(_options, {call, _body}) do
    { state, request } = call_signature(call)
    quote do
      def handle_call(unquote(request), _, unquote(var!(state))) do
        __MODULE__.Implementation.unquote(call)
        |> Service.Common.create_genserver_response(unquote(var!(state)))
      end
    end
  end


  def generate_implementation(_options, {call, body}) do
    quote do
      def(unquote(call), unquote(body))
    end
  end

  # only used for pools
  def generate_delegator(_options, {_call, _body}), do: nil
  
  # given def fred(store, a, b) return { store, { :fred, a, b }}

  def call_signature({ name, _, [ server | args ] }) do
    {
      var!(server),
      { :{}, [], [ name |  Enum.map(args, fn a -> var!(a) end) ] }
    }
  end


  
end
