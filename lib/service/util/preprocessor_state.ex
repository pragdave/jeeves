defmodule Service.Util.PreprocessorState do

  @name :"-- pragdave.me.preprocessor.state --"
  
  defstruct(
    functions:  [],     # the list of { call, body }s from each def
    options:    [],     # the options from `use`
   )
  

  def start_link(options) do
    { :ok, _ } = Agent.start_link(
      fn ->
        %__MODULE__{options: options}
      end,
      name: @name
    )    
  end

  def stop do
    Agent.stop(@name)
  end

  def options do
    Agent.get(@name, &(&1.options))
  end
  
  def add_function(func) do
    Agent.update(@name, fn state ->
      %{ state | functions: [ func | state.functions ] }
    end)
  end

  def function_list do
    Agent.get(@name, &(&1.functions))
  end

end
