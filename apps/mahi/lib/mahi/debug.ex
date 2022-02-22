defmodule Mahi.Debug do
  @moduledoc """
  Helper module for debugging purposes
  """

  @upload_files_path "#{__DIR__}/../../test/fixtures/uploads"

  def new_chunk_with_chunks do
    id = Mahi.Uploads.new_chunk_upload("nalu.png", 30000, 8)

    upload_chunks(id)

    id
  end

  def upload_chunks(id) do
    file_paths =
      Path.wildcard("#{@upload_files_path}/segment**")
      |> Enum.sort()

    for {file_path, chunk_number} <- Enum.with_index(file_paths, 1) do
      Mahi.Uploads.append_chunk(id, {chunk_number, file_path})
    end
  end
end
