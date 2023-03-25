defmodule Uploader.Domain.Chunk do
  @enforce_keys ~w(chunk_number)a

  defstruct ~w(chunk_number file_path)a
end
