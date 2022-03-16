defmodule Oriio.TestCluster do
  def start_nodes(number) do
    :ok = :net_kernel.monitor_nodes(true)
    _ = :os.cmd('epmd -daemon')
    Node.start(:master@localhost, :shortnames)

    Enum.each(1..number, fn index ->
      :slave.start_link(:localhost, 'slave_#{index}')
    end)

    [node() | Node.list()]
  end

  def stop_nodes(list) do
    Enum.map(list, &Node.disconnect(&1))
  end
end
