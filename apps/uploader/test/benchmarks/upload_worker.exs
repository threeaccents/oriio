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

  def rand_number() do
    :rand.uniform(5_000)
  end
end

{:ok, upload_id} = Uploader.new_upload("test.txt", 20_000)

pid = TO.get_upload_pid!(upload_id)

test_chunk_file =
  "/home/threeaccents/work/threeaccents/code/threeaccents/oriio/data/fixtures/uploads/segmentaa"

Benchee.run(%{
  "single_order_map" => fn ->
    Uploader.UploadWorker.append_chunk_map(pid, 500, test_chunk_file)
  end,
  "single_avl" => fn -> Uploader.UploadWorker.append_chunk_avl(pid, 500, test_chunk_file) end,
  "single_bst" => fn -> Uploader.UploadWorker.append_chunk(pid, 500, test_chunk_file) end,
  "single_list" => fn -> Uploader.UploadWorker.append_chunk_list(pid, 500, test_chunk_file) end,
  "multiple_order_map" => fn ->
    for iter <- 1..1000 do
      Uploader.UploadWorker.append_chunk_map(pid, TO.rand_number(), test_chunk_file)
    end
  end,
  "multiple_avl" => fn ->
    for iter <- 1..1000 do
      Uploader.UploadWorker.append_chunk_avl(pid, TO.rand_number(), test_chunk_file)
    end
  end,
  "multiple_bst" => fn ->
    for iter <- 1..1000 do
      Uploader.UploadWorker.append_chunk(pid, TO.rand_number(), test_chunk_file)
    end
  end,
  "multiple_list" => fn ->
    for iter <- 1..1000 do
      Uploader.UploadWorker.append_chunk_list(pid, TO.rand_number(), test_chunk_file)
    end
  end
})
