defmodule Oriio.Uploads.SignedUploadWorker do
  @moduledoc """
  Worker that keeps track of a signed upload.
  """

  use GenServer, restart: :transient

  alias Oriio.Uploads.SignedUploadRegistry
  alias Oriio.Uploads.SignedUploadStateHandoff, as: StateHandoff

  require Logger

  @type upload_type() :: :default | :chunked

  @type state() :: %{
          id: Ecto.UUID.t(),
          is_started?: boolean(),
          must_begin_by: DateTime.t(),
          upload_type: upload_type()
        }

  @type new_signed_upload() :: %{
          id: Ecto.UUID.t(),
          must_begin_by: DateTime.t(),
          upload_type: upload_type()
        }

  @spec start_link(new_signed_upload()) :: GenServer.on_start()
  def start_link(new_signed_upload) do
    GenServer.start_link(__MODULE__, new_signed_upload, name: via_tuple(new_signed_upload.id))
  end

  @impl GenServer
  def init(new_signed_upload) do
    Process.flag(:trap_exit, true)

    state = Map.put(new_signed_upload, :is_started?, false)

    {:ok, state, {:continue, :load_state}}
  end

  @spec start_upload(pid()) :: :ok
  def start_upload(server) do
    GenServer.call(server, :start_upload)
  end

  @spec is_started?(pid()) :: boolean()
  def is_started?(server) do
    GenServer.call(server, :is_started)
  end

  @impl GenServer
  def handle_call(:start_upload, _from, state) do
    case state do
      %{is_started?: false} -> {:reply, :ok, Map.put(state, :is_started?, true)}
      _ -> {:reply, {:error, :signed_upload_already_in_use}, state}
    end
  end

  @impl GenServer
  def handle_call(:is_started, _from, state) do
    {:reply, Map.get(state, :is_started?), state}
  end

  @impl GenServer
  def handle_continue(:load_state, %{id: id} = state) do
    new_state =
      case StateHandoff.pickup(id) do
        nil -> state
        state -> state
      end

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:EXIT, _, :normal}, state) do
    {:stop, :normal, state}
  end

  @impl GenServer
  def terminate(:normal, _state), do: :ok

  def terminate(_reason, %{id: id} = state) do
    StateHandoff.handoff(id, state)
    # timeout to make sure the CRDT is propegated to other nodes
    :timer.sleep(3000)
  end

  defp via_tuple(name),
    do: {:via, Horde.Registry, {SignedUploadRegistry, name}}
end
