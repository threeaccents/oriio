defmodule Uploader.CompleteUploadActionTest do
  use ExUnit.Case

  alias Uploader.CompleteUploadAction

  describe "perform/1" do
    test "it finds the upload worker pid" do
      {:ok, upload_id} = Uploader.new_upload("myname.jpg", 1)

      {:ok, action} = Uploader.CompleteUploadAction.perform(%{upload_id: upload_id})
    end
  end
end
