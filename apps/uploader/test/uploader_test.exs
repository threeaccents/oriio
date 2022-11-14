defmodule UploaderTest do
  use ExUnit.Case

  describe "complete upload action" do
    test "yolo" do
      {:ok, upload_id} = Uploader.new_upload("myname.jpg", 1)

      {:ok, action} = Uploader.CompleteUploadAction.perform(%{upload_id: upload_id})

      IO.inspect(action)

      assert is_pid(action.upload_pid)
    end
  end
end
