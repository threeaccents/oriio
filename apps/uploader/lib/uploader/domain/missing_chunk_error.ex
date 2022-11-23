defmodule Uploader.Domain.MissingChunksError do
  defstruct message: "missing chunks to complete upload", chunks: [], upload_id: nil
end
