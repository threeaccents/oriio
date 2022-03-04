defmodule Oriio.Uploads.UploadWorker do
  @moduledoc """
  GenServer for handling uploads. It keeps track of the upload state and merging of a chunk upload.
  For regular uploads it is mainly used for signed regular uploads for the system to keep track of any
  "requested" upload. In chunked uploads it is used for both signed and unsigned uploads.
  """
end
