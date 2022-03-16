_ = :os.cmd('epmd -daemon')

:ok = LocalCluster.start()

{:ok, _} = Application.ensure_all_started(:oriio)

ExUnit.start()
