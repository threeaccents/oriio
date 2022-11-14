defmodule Uploader.UploadNotFound do
  @moduledoc """
  Error raised when an upload is not found.
  """

  defexception message: "chunk upload not found"
end
