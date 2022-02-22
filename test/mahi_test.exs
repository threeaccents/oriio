defmodule MahiTest do
  use ExUnit.Case

  test "merge file chunks" do
    original_file_hash = "AE06AFD6F4E33F438B38DD4EA9D0C6259016BE222D7088E067AE5CE9303C8C4B"

    file_paths = Path.wildcard("#{File.cwd!()}/test/files/segment**") |> Enum.sort()

    id = Mahi.new_chunk_upload("test.png", 11111, length(file_paths))

    for {file_path, chunk_number} <- Enum.with_index(file_paths, 1) do
      Mahi.append_chunk(id, {chunk_number, file_path})
    end

    merged_file_path = Mahi.complete_chunk_upload(id)

    merged_file_hash = file_hash(merged_file_path)

    assert merged_file_hash == original_file_hash
  end

  defp file_hash(file_path) do
    File.stream!(file_path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), fn line, acc -> :crypto.hash_update(acc, line) end)
    |> :crypto.hash_final()
    |> Base.encode16()
  end
end
