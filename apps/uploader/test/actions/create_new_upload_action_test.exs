defmodule Uploader.CreateNewUploadActionTest do
  use ExUnit.Case

  alias Uploader.CreateNewUploadAction

  describe "perform/2" do
    test "it generates an upload id" do
      params = %{file_name: "test_file", total_chunks: 0}

      assert {:ok, %{upload_id: upload_id}} = CreateNewUploadAction.perform(params)

      assert {:ok, _} = Ecto.UUID.cast(upload_id)
    end

    test "it starts an upload worker" do
      params = %{file_name: "test_file", total_chunks: 0}

      assert {:ok, %{worker_started?: true}} = CreateNewUploadAction.perform(params)
    end
  end
end
