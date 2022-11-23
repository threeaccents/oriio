defmodule Uploader.CompleteUploadActionTest do
  use ExUnit.Case

  alias Uploader.CompleteUploadAction
  alias Uploader.Domain.MissingChunksError

  describe "perform/1" do
    test "it finds the upload worker pid" do
      {:ok, upload_id} = Uploader.new_upload("myname.jpg", 1)

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
               upload_id: upload_id,
               message: "missing chunks to complete upload"
             } = err
    end
  end
end
