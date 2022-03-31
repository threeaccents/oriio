defmodule Oriio.Uploads.UploadMonitorTest do
  use Oriio.DataCase

  alias Oriio.Uploads.UploadMonitor

  describe "start_link/1" do
    test "returns :ignore if process has already been started" do
      # monitor process starts automatically so the process has already started before making the call here
      assert :ignore = UploadMonitor.start_link([])
    end
  end

  describe "init/1" do
    test "sets the correct state for the GenServer" do
      assert {:ok, state} = UploadMonitor.init([])

      assert [] = state
    end
  end

  describe "distributed supervisor" do
    test "process is restarted on another node" do
      LocalCluster.start_nodes("my-cluster", 3)

      # let the registry sync up
      :timer.sleep(1000)

      monitor_pid = start_upload_monitor()

      original_node_with_monitor = node(monitor_pid)

      :rpc.call(original_node_with_monitor, :init, :stop, [])

      # let the registry sync up
      :timer.sleep(1000)

      monitor_pid = Oriio.Debug.get_upload_monitor_pid()

      new_node_with_monitor = node(monitor_pid)

      assert new_node_with_monitor != original_node_with_monitor
    end
  end

  defp start_upload_monitor do
    monitor_pid = Oriio.Debug.get_upload_monitor_pid()

    # make sure the monitor is not running on the main node as we will kill the node in the test.
    if node(monitor_pid) == node() do
      Process.exit(monitor_pid, :kill)

      # let the registry sync up
      :timer.sleep(1000)

      start_upload_monitor()
    else
      monitor_pid
    end
  end
end
