defmodule Oriio.Uploads.ChunkUploadWorkerTest do
  use Oriio.DataCase

  alias Oriio.Uploads.ChunkUploadWorker
  alias Oriio.Documents
  alias Oriio.Debug
  alias Ecto.UUID

  @total_chunks 8
  @upload_files_path "#{__DIR__}/../../../fixtures/uploads"

  describe "init/1" do
    test "sets the correct state for the GenServer" do
      assert {:ok, state, _} = ChunkUploadWorker.init(new_chunk_upload())

      assert %{
               id: _id,
               file_name: _fn,
               total_chunks: _tc,
               chunk_document_paths: _cdp,
               merged_chunks?: _mc,
               updated_at: %DateTime{}
             } = state
    end

    test "calls handle_continue to load potential state" do
      assert {:ok, _state, {:continue, :load_state}} = ChunkUploadWorker.init(new_chunk_upload())
    end

    test "chunk_document_paths gets properly set based on the total chunks" do
      assert {:ok, state, _} = ChunkUploadWorker.init(new_chunk_upload())

      assert length(state.chunk_document_paths) == @total_chunks
    end
  end

  describe "append_chunk/2" do
    setup ctx do
      {:ok, pid} = start_supervised({ChunkUploadWorker, new_chunk_upload()})
      Map.put(ctx, :pid, pid)
    end

    test "the chunk is appended to the proper chunk key", %{pid: pid} do
      path = Briefly.create!()

      new_chunk = {2, path}

      assert :ok = ChunkUploadWorker.append_chunk(pid, new_chunk)

      %{chunk_document_paths: chunk_document_paths} = :sys.get_state(pid)

      # verify all other chunk paths remain nil
      for {chunk_number, path} <- chunk_document_paths, chunk_number != :"2" do
        assert path == nil
      end

      # verify chunk number 2 gets set to a proper path
      path = Keyword.get(chunk_document_paths, :"2")

      assert path != nil
      assert File.exists?(path)
    end
  end

  describe "complete_chunk/1" do
    setup ctx do
      {:ok, pid} = start_supervised({ChunkUploadWorker, new_chunk_upload()})
      Map.put(ctx, :pid, pid)
    end

    test "returns missing chunks if any chunks are missing", %{pid: pid} do
      add_chunks(pid, [1, 2, 3, 4, 5])

      assert {:error, msg} = ChunkUploadWorker.complete_upload(pid)

      assert msg == "missing chunks [6, 7, 8]"
    end

    test "merges chunks into 1 file", %{pid: pid} do
      original_file_hash = "1DA01AE7787DD239587F7DE7D901552B"

      document_paths =
        Path.wildcard("#{@upload_files_path}/segment**")
        |> Enum.sort()

      for {document_path, chunk_number} <- Enum.with_index(document_paths, 1) do
        ChunkUploadWorker.append_chunk(pid, {chunk_number, document_path})
      end

      assert {:ok, merged_document_path} = ChunkUploadWorker.complete_upload(pid)

      merged_file_hash = file_hash(merged_document_path)

      assert merged_file_hash == original_file_hash
    end
  end

  describe "distributed supervisor" do
    test "process is restarted on another node" do
      LocalCluster.start_nodes("my-cluster", 3)

      upload_id = new_distributed_chunk_upload()

      # let the registry sync up
      :timer.sleep(1000)

      # upload chunk to update upload state
      Documents.append_chunk(upload_id, {1, Briefly.create!()})

      upload_pid = Oriio.Debug.get_chunk_upload_pid(upload_id)

      original_node_with_upload = node(upload_pid)

      :rpc.call(original_node_with_upload, :init, :stop, [])

      # let everything sync up
      :timer.sleep(5000)

      upload_pid = Oriio.Debug.get_chunk_upload_pid(upload_id)

      new_node_with_upload = node(upload_pid)

      assert new_node_with_upload != original_node_with_upload

      :ok = LocalCluster.stop()
    end

    test "state is handed off between processes" do
      {:ok, upload_id} = Documents.new_chunk_upload("nalu.png", 8)

      og_upload_pid = Debug.get_chunk_upload_pid(upload_id) |> IO.inspect(label: "old pid")

      :ok = Documents.append_chunk(upload_id, {1, Briefly.create!()})

      og_upload_state = :sys.get_state(og_upload_pid) |> IO.inspect(label: "old state")

      Process.exit(og_upload_pid, :testkill)

      # let everything sync up
      :timer.sleep(5000)

      new_upload_pid = Debug.get_chunk_upload_pid(upload_id) |> IO.inspect(label: "new pid")
      new_upload_state = :sys.get_state(new_upload_pid) |> IO.inspect(label: "new state")

      assert og_upload_pid != new_upload_pid
      assert og_upload_state == new_upload_state
    end
  end

  defp new_distributed_chunk_upload() do
    {:ok, upload_id} = Documents.new_chunk_upload("nalu.png", 8)

    # let the registry sync up
    :timer.sleep(500)

    upload_pid = Oriio.Debug.get_chunk_upload_pid(upload_id)

    # make sure the upload is not running on the current node as we will kill the node in the test.
    if node(upload_pid) == node() do
      new_distributed_chunk_upload()
    else
      upload_id
    end
  end

  defp add_chunks(pid, chunks) when is_list(chunks) do
    for chunk_number <- chunks do
      add_chunk(pid, chunk_number)
    end
  end

  defp add_chunk(pid, chunk_number) do
    path = Briefly.create!()

    new_chunk = {chunk_number, path}

    :ok = ChunkUploadWorker.append_chunk(pid, new_chunk)
  end

  defp file_hash(document_path) do
    File.stream!(document_path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(:md5), fn line, acc -> :crypto.hash_update(acc, line) end)
    |> :crypto.hash_final()
    |> Base.encode16()
  end

  defp new_chunk_upload(_opts \\ []) do
    %{
      id: UUID.generate(),
      file_name: "test.jpg",
      total_chunks: @total_chunks
    }
  end
end
