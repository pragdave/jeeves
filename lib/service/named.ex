defmodule Service.Named do

  require Service.Common
  
  defmacro __using__(opts \\ []) do
    Service.Common.generate_common_code(__MODULE__, opts, service_name(opts))
  end

  defmacro generate_code_callback(_) do
    Service.Common.generate_code(__MODULE__)
  end
  
  def generate_api_call(options, {call, _body}) do
    quote do
      def(unquote(call), do: unquote(api_body(options, call)))
    end
  end

  defp api_body(options, call) do
    request = call_signature(call)
    quote do
      GenServer.call(unquote(service_name(options)), unquote(request))
    end
  end
  
  def generate_handle_call(options, {call, _body}) do
    request  = call_signature(call)
    api_call = api_signature(options, call)
    state_var = { state_name(options), [], nil }
    
    quote do
      def handle_call(unquote(request), _, unquote(state_var)) do
        __MODULE__.Implementation.unquote(api_call)
        |> Service.Common.create_genserver_response(unquote(state_var))
      end
    end
  end


  def generate_implementation(options, {call, body}) do
    quote do
      def(unquote(api_signature(options, call)), unquote(body))
    end
  end

  # only used for pools
  def generate_delegator(_options, {_call, _body}), do: nil
  
  
  # given def fred(a, b) return { :fred, a, b }

  def call_signature({ name, _, args }) do
    { :{}, [], [ name |  Enum.map(args, fn a -> var!(a) end) ] }
  end

  # given def fred(a, b) return def fred(«state name», a, b)
  
  def api_signature(options, { name, context, args }) do
    { name, context, [ { state_name(options), [], nil } | args ] }
  end

  def service_name(options) do
    options[:service_name] || quote(do: __MODULE__)
  end

  def state_name(options) do
    options[:state_name] || :state
  end
end
