defmodule Mahi.UploadsTest do
  use Mahi.DataCase

  alias Mahi.Uploads

  @upload_files_path "#{__DIR__}/../fixtures/uploads"

  test "merge file chunks" do
    IO.inspect(__DIR__)
    original_file_hash = "1DA01AE7787DD239587F7DE7D901552B"

    file_paths =
      Path.wildcard("#{@upload_files_path}/segment**")
      |> Enum.sort()

    id = Uploads.new_chunk_upload("test.png", 11111, length(file_paths))

    for {file_path, chunk_number} <- Enum.with_index(file_paths, 1) do
      Uploads.append_chunk(id, {chunk_number, file_path})
    end

    merged_file_path = Uploads.complete_chunk_upload(id)

    merged_file_hash = file_hash(merged_file_path)

    assert merged_file_hash == original_file_hash
  end

  defp file_hash(file_path) do
    File.stream!(file_path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(:md5), fn line, acc -> :crypto.hash_update(acc, line) end)
    |> :crypto.hash_final()
    |> Base.encode16()
  end
end
