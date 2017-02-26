defmodule CommonTest do
  use ExUnit.Case
  alias Service.Util.PreprocessorState, as: PS
  require Service.Common
  alias Service.Common, as: SC

  @name __MODULE__
  
  test "calling `def` adds the function to the preprocessor state, but emits no code" do
    PS.start_link(@name, nil)
    result = SC.def_implementation(@name, :dave, :body)
    assert result == nil
    assert [ function ] = PS.function_list(@name)
    assert elem(function, 0) == :dave
    assert elem(function, 1) == :body
  end


  test "set_state() returns an OTP reply with the new state" do
    assert { :reply, :value, :new_state } == SC.set_state(:new_state, do: :value)
  end

  defmodule TestStrategy do
    def generate_api_call(_options, _func),       do: :api
    def generate_handle_call(_options, _func),    do: :handle
    def generate_implementation(_options, _func), do: :impl
    def generate_delegator(_options, _func),      do: :delegator
  end

  test "the strategy is called to generate functions" do
    PS.start_link(@name, [])
    func = quote do
      def name(a1, a2) do
        a1 + a2
      end
    end
    
    { options, apis, handlers, impls, delegators } =
      SC.generate_functions(TestStrategy, :options, func, {nil, [], [], [], []})

    assert options    == :options
    assert apis       == [:api]
    assert impls      == [:impl]
    assert handlers   == [:handle]
    assert delegators == [:delegator]
  end

  test "if a return value is not a genserver reply, wrap it in one" do
    state = 123

    assert { :reply, :return_value, ^state } =
      SC.create_genserver_response(:return_value, state)
  end

  test "if a return value is a genserver reply, don't wrap it in another" do
    state = 0
    assert { :reply, :return_value, :new_state } =
      SC.create_genserver_response({:reply, :return_value, :new_state}, state)
  end
  
end
