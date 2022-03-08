defmodule Oriio.DeltaCrdt do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      cluster = opts[:cluster]

      opts =
        opts
        |> Keyword.put_new(:cluster_mod, {cluster || Oriio.DeltaCrdt, []})
        |> Keyword.put_new(:cluster_name, cluster || __MODULE__)
        |> Keyword.put_new(:crdt_mod, :"#{__MODULE__}.Crdt")
        |> Keyword.put_new(:crdt_opts, [])

      @crdt opts[:crdt_mod]

      defmodule CrdtSupervisor do
        use Supervisor

        @cluster_name opts[:cluster_name]
        @cluster_mod opts[:cluster_mod]
        @crdt opts[:crdt_mod]
        @crdt_opts opts[:crdt_opts]

        def start_link(init_opts) do
          Supervisor.start_link(__MODULE__, init_opts, name: __MODULE__)
        end

        @impl true
        def init(init_opts) do
          crdt_opts =
            [crdt: DeltaCrdt.AWLWWMap]
            |> Keyword.merge(@crdt_opts)
            |> Keyword.merge(init_opts)
            |> Keyword.put(:name, @crdt)

          {cluster_mod, cluster_opts} = @cluster_mod

          cluster_opts =
            [crdt: @crdt, name: @cluster_name]
            |> Keyword.merge(cluster_opts)
            |> Keyword.merge(init_opts)

          children = [
            {DeltaCrdt, crdt_opts},
            {Horde.NodeListener, @cluster_name},
            {cluster_mod, cluster_opts}
          ]

          Supervisor.init(children, strategy: :one_for_one)
        end
      end

      def child_spec(opts) do
        CrdtSupervisor.child_spec(opts)
      end
    end
  end

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def init(opts) do
    members = Horde.NodeListener.make_members(opts[:name])

    state =
      opts
      |> Enum.into(%{})
      |> Map.put(:members, members)

    {:ok, state}
  end

  @impl true
  def handle_call({:set_members, members}, _from, state = %{crdt: crdt, name: name}) do
    neighbors =
      members
      |> Stream.filter(fn member -> member != {name, Node.self()} end)
      |> Enum.map(fn {_, node} -> {crdt, node} end)

    DeltaCrdt.set_neighbours(crdt, neighbors)

    {:reply, :ok, %{state | members: members}}
  end

  @impl true
  def handle_call(:members, _from, state = %{members: members}) do
    {:reply, MapSet.to_list(members), state}
  end
end
