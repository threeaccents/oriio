defmodule Oriio.Uploads.UploadMonitorTest do
  use Oriio.DataCase

  alias Oriio.Uploads.UploadMonitor

  describe "start_link/1" do
    test "returns :ignore if process has already been started" do
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
    @tag mustexec: true
    test "process is restarted on another node" do
      LocalCluster.start_nodes("my-cluster", 3)

      # let the registry sync up
      :timer.sleep(1000)

      # start_upload_monitor()

      monitor_pid = Oriio.Debug.get_upload_monitor_pid()

      original_node_with_monitor = node(monitor_pid)

      IO.inspect("first")
      IO.inspect(monitor_pid)
      IO.inspect(original_node_with_monitor)

      node_ref = Process.monitor(monitor_pid)

      :rpc.call(original_node_with_monitor, :init, :stop, [])

      assert_receive {:DOWN, ^node_ref, :process, _, :normal}, 500

      IO.inspect("killed node")

      # # let the registry sync up
      # :timer.sleep(1000)

      monitor_pid = Oriio.Debug.get_upload_monitor_pid()

      new_node_with_monitor = node(monitor_pid)

      IO.inspect("second")
      IO.inspect(monitor_pid)
      IO.inspect(new_node_with_monitor)

      assert new_node_with_monitor != original_node_with_monitor

      :ok = LocalCluster.stop()
    end
  end

  defp start_upload_monitor do
    # let the registry sync up
    :timer.sleep(500)

    monitor_pid = Oriio.Debug.get_upload_monitor_pid()

    IO.inspect("start upload monitor")
    IO.inspect(monitor_pid)

    # make sure the monitor is not running on the current node as we will kill the node in the test.
    if node(monitor_pid) == node() do
      start_upload_monitor()
    else
      monitor_pid
    end
  end
end
