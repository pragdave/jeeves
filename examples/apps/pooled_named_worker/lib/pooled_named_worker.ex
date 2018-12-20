defmodule PooledNamedWorker do

  use(
    Jeeves.Pooled,
    state:        %{ a: 1 },
    service_name: Vince,
    pool:         [ min: 2, max: 4 ],
    show_code: true
  )

  def process() do
    IO.puts "in pool worker #{inspect self()} #{inspect state}"
    :timer.sleep(1000)
    set_state(%{ state | a: state.a + 1 }) do
      "#{inspect self()} done"
    end
  end
  
end






