defmodule Oriio.Uploads.UploadMonitorRegistry do
  @moduledoc """
  Distributed registry for UploadMonitor
  """

  use Horde.Registry

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    Horde.Registry.start_link(__MODULE__, [keys: :unique], name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.Registry.init()
  end

  defp members do
    Enum.map([Node.self() | Node.list()], &{__MODULE__, &1})
  end
end
