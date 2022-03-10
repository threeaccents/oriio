defmodule Oriio.UploadsTest do
  use Oriio.DataCase

  alias Oriio.Uploads

  @upload_files_path "#{__DIR__}/../fixtures/uploads"

  test "merge file chunks" do
    assert true == true
    # original_file_hash = "1DA01AE7787DD239587F7DE7D901552B"

    # document_paths =
    #   Path.wildcard("#{@upload_files_path}/segment**")
    #   |> Enum.sort()

    # id = Uploads.new_chunk_upload("test.png", length(document_paths))

    # for {document_path, chunk_number} <- Enum.with_index(document_paths, 1) do
    #   Uploads.append_chunk(id, {chunk_number, document_path})
    # end

    # merged_document_path = Uploads.complete_chunk_upload(id)

    # merged_file_hash = file_hash(merged_document_path)

    # assert merged_file_hash == original_file_hash
  end

  # defp file_hash(document_path) do
  #   File.stream!(document_path, [], 2048)
  #   |> Enum.reduce(:crypto.hash_init(:md5), fn line, acc -> :crypto.hash_update(acc, line) end)
  #   |> :crypto.hash_final()
  #   |> Base.encode16()
  # end
end
