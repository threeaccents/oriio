alias Uploader.UploadRegistry

defmodule TO do
  def get_upload_pid!(upload_id) do
    case GenServer.whereis({:via, Horde.Registry, {UploadRegistry, upload_id}}) do
      nil ->
        raise UploadNotFound

      pid ->
        pid
    end
  end
end

{:ok, upload_id} = Uploader.new_upload("test.txt", 20_000)

pid = TO.get_upload_pid!(upload_id)

test_chunk_file =
  "/home/threeaccents/work/threeaccents/code/threeaccents/oriio/data/fixtures/uploads/segmentaa"

Benchee.run(%{
  "bst" => fn -> Uploader.UploadWorker.append_chunk(pid, 500, test_chunk_file) end,
  "order_map" => fn -> Uploader.UploadWorker.append_chunk_map(pid, 500, test_chunk_file) end,
  "list" => fn -> Uploader.UploadWorker.append_chunk_list(pid, 500, test_chunk_file) end
})
