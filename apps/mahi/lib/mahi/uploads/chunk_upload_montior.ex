defmodule Mahi.Uploads.ChunkUploadMonitor do
  @moduledoc """
  This module will check for stale uploads that maybe the client got disconnected for 5 hours and sent no more chunks to avoid process leaks.
  It will also check for chunks that have been merged and for some reason the process wasn't killed.
  """
end
