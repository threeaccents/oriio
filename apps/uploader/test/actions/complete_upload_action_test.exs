defmodule Uploader.CompleteUploadActionTest do
  use ExUnit.Case

  alias Uploader.CompleteUploadAction
  alias Uploader.Domain.MissingChunksError

  @upload_files_dir "#{__DIR__}/../../../../data/fixtures/uploads"

  describe "perform/1" do
    test "it finds the upload worker pid" do
      assert {:ok, upload_id} = Uploader.new_upload("myname.jpg", 1)

      assert :ok = Uploader.append_chunk(upload_id, 1, "#{@upload_files_dir}/segmentaa")

      assert {_, %{upload_pid: upload_pid}} =
               CompleteUploadAction.perform(%{upload_id: upload_id})

      assert is_pid(upload_pid)
    end

    test "it returns any missing chunks" do
      {:ok, upload_id} = Uploader.new_upload("myname.jpg", 2)

      assert {:error, %MissingChunksError{} = err} =
               CompleteUploadAction.perform(%{upload_id: upload_id})

      assert %MissingChunksError{
               chunks: [1, 2],
               upload_id: ^upload_id,
               message: "missing chunks to complete upload"
             } = err
    end

    test "it concatenates chunks into 1 file" do
      original_file_hash = "1DA01AE7787DD239587F7DE7D901552B"

      document_paths = Path.wildcard("#{@upload_files_dir}/segment**")

      {:ok, upload_id} = Uploader.new_upload("myname.jpg", length(document_paths))

      for {document_path, chunk_number} <- Enum.with_index(document_paths, 1) do
        Uploader.append_chunk(upload_id, chunk_number, document_path)
      end

      assert {:ok, %{concatenated_file_path: concatenated_file_path}} =
               CompleteUploadAction.perform(%{upload_id: upload_id})

      concat_file_hash = file_hash(concatenated_file_path)

      IO.inspect(concat_file_hash)

      assert concat_file_hash == original_file_hash
    end

    defp file_hash(document_path) do
      File.stream!(document_path, [], 2048)
      |> Enum.reduce(:crypto.hash_init(:md5), fn line, acc -> :crypto.hash_update(acc, line) end)
      |> :crypto.hash_final()
      |> Base.encode16()
    end
  end
end
