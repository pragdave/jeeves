# Types of Services

## Named vs. Anonymous

There's a fundamental difference between named and anonymous servers.
The difference isn't one of implementation—the two forms are basically
the same. It's a difference of intent.

A named server is effectively a singleton—a global object. If it has
state, that state is only meaningful globally—it is not the property
of any one client process. Loggers, time services, and so on are all
examples of named, singleton servers.

Anonymous services have a different intent. Because they are accessed
via a handle (a reference or) pid, they have an owner—the process that
has that handle. Ownership can be shared, but that sharing is
controlled by the original creator of the server.

The state of anonymous servers can therefore be specific to a
particular owner. If we use a server to have a conversation with a
remote service, for example, we own that server, and it can maintain
the state of the connection between requests.

## Solo vs Pooled

A solo service is a single process. When a client makes a request,
that process is executed. No other client can run code in that service
until it is idle again.

A pooled service contains zero or more workers. Each worker is
equivalent to a solo service, in that it handles work requests for one
client at a time. However, a pooled service also contains a pool
manager (or scheduler). Requests for the pool service are not sent to
the worker directly. Instead, they are sent to the scheduler. If it
has a free worker process, it forwards on the request. If it does not,
it delays execution of the caller until a worker becomes free (or a
timeout occurs).

A pooled service can be configured to support some maximum number of
workers. It will dynamically create new workers to handle requests if
all existing workers are busy _and_ if the worker count is less than
the maximum.

Pooled services are useful when you want to achieve parallelism and
the work performed by the service is likely to run for a nontrivial
time. They are also useful as a way to hold on to expensive resources
(such as database connections).

# Coding Model

Permuting named and anonymous services with solo and pooled
provisioning gives us four categories of service.

From a coding standpoint, though, the most significant difference is
between named and anonymous services (whether they are solo or
pooled).

A named service has its own state. That state is not passed to it on
each request.

An anonymous service (logically) does not have a single state.
Instead, the state is established for it each time it is called
(typically by passing it a server pid).

This means that our APIs will be different. For a named service, such
as a logger, we might write:

~~~ elixir
Logger.info("Starting")
~~~
    
For an anonymous service, such as a database connection, we need to
create it to get a handle, and then pass that handle to it on each
request.

~~~ elixir
{ :ok, handle } = DBConnection.start_link(«params»)
# ...
DB.insert(handle, «stuff»)
~~~

Because of this, Diet.Service comes in two flavors, one for named
services and one for anonymous ones.

## Defining a Named Service

~~~ elixir
defmodule MyLogger do

  defstruct device: :stdio

  use Service.Named,
      state: [ logger: %MyLogger{} ]

  def info(msg) do
    IO.puts(logger.device, "-- #{msg}")
  end
  
  def set_device(new_device) do
    set_state(%{ logger | device: new_device}) do
      :ok
    end
  end

end
~~~

By default, `MyLogger` will be spawned when the application starts.
The service will (by default) have the same name as the module
(`Elixir.MyLogger` in this case).

Its state is defined by the clause:

~~~ elixir
state: [ logger: %MyLogger{} ]
~~~

<span id="why-magic-state">Inside</span> the module's public functions, the state
will be made available via the variable `logger`. The initial value of
the state will be the struct defined in this same module.

Yes, this is magic, and it's probably frowned on by José. However,
doing this makes the module's API consistent. You call an API function
using the signature in the module definition. It's really no different
to the implicit `this` variable in OO code.

## Defining an Anonymous Service

~~~ elixir
defmodule KVStore do

  use Service.Anonymous
      state: %{}

  def put(store, key, value) do
    set_state(Map.put(store, key, value), do: value
  end
  
  def get(store, key) do
    store[key]
  end

end
~~~

Here's how you'd use this:

~~~ elixir
handle = KVStore.run()
KVStore.put(handle, :name, "José")
IO.puts KVStore.get(handle, :name)
~~~

What if you wanted to pass some initial values into the store? There
are a couple of techniques. First, any parameter passed to `run()`
will by default become the initial state.

But if your service has some specific internal formatting that must be
applied to this state, simply provide an `init_state()` function. This
receives the default state and the parameter passed to `run()`, and
returns the updated state.


~~~ elixir
defmodule KVStore do

  use Service.Anonymous
      state: %{}

  def init_state(default_state, initial_values) when is_list(initial_values) do
    initial_values |> Enum.into(default_state)
  end
  
  # ...
end
~~~

Call this with:

~~~ elixir
handle = KVStore.run(name: "Jose", language: "Elixir")

KVStore.put(handle, :name, "José")

IO.puts KVStore.get(handle, :name)      # => José
IO.puts KVStore.get(handle, :language)  # => Elixir
~~~

## Creating Pooled Services

You can create both named and anonymous pooled services. Simply add
the `pool:` option:

~~~ elixir
defmodule DBConnection do
  defstruct conn: nil, created: fn () -> DateTime.utc_now() end

  use(Service.Named,
      state: [ db: %DBConnection{} ],
      pool:  [ min: 2, max: 10, retire_after: 5*60 ])

  def init_state(state, _) do
    connection_params = Application.fetch_env(app, :db_params)
    conn = PG.connect(connection_params)
    %{ state | conn: conn }
  end

  def execute(stmt) do
    PG.execute(db.conn, stmt)
  end
  # ...
end
~~~

This creates a pool of database connections. It will always have at
least 2 workers running, and may have up to 10. Idle workers will be
culled after 5 minutes.

Here's how it is called:

~~~ elixir
result = DBConnection.execute("select * from table1")
~~~


#### anon pools NYI
    You can also create anonymous pools. As with other anonymous services,
    you'll need to keep track of the handle.
    
    Here's the same database connection pool code, but set up to allow you
    to create different pools for different databases.
    
    ~~~ elixir
    defmodule DBConnection do
      defstruct conn: nil, created: fn () -> DateTime.utc_now() end
    
      use(Service.Pool,
          state: [ db: %DBConnection{} ],
          pool:  [ min: 2, max: 10, retire_after: 5*60 ])
    
      def init_state(state, connection_params) do
        conn = PG.connect(connection_params)
        %{ state | conn: conn }
      end
    
      def execute(stmt) do
        PG.execute(db.conn, stmt)
      end
      # ...
    end
    ~~~
    
    The only changes were to alter the type to `Diet.Service.Anonymous`
    and to change the `new` function to accept the database connection to
    be used.


# Supervision

(to be implemented using JVs child_spec proposal)

## Pooled Supervision

When you create a pooled service, Service always creates a couple of
supervisors and a scheduler process. This looks like the following:


                           +--------------------+
                           |                    |
                           |  Pool Supervisor   |
                         / |                    |\
                        /  +--------------------+ \
                       /                           \
    +--------------------+                       +--------------------+
    |                    |                       |                    |
    |    Scheduler       |                       | Worker Supervisor  |
    |                    |                       |                    |
    +--------------------+                       +--------------------+
                                                           |
                                                           |
                                                           v
                                                        +-----------------+
                                                    +------------------+  |
                                               +--------------------+  |  |
                                               |                    |  |  |
                                               |      Workers       |  |--+
                                               |                    |--+
                                               +--------------------+


When your client code accesses a pooled service, it is actually
talking to the scheduler process.


## State Protection (NYI)

If you add the option `protect_state: true`, Diet will automatically
create an additional top-level supervisor and a vault process that does
nothing but save the state of services between requests. Should a
service crash, the supervisor will restart it using the saved state
from the vault, rather than using the default state.
