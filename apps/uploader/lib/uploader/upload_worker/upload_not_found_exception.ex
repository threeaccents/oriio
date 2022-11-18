defmodule Uploader.UploadNotFound do
  @moduledoc """
  Error raised when an upload is not found.
  """

  defexception message: "upload not found"
end
