defmodule WebApi.PageControllerTest do
  use WebApi.ConnCase

  # move fixtures to the root to share between both.
  @upload_files_dir "#{__DIR__}/../../../../oriio/test/fixtures/uploads"

  setup %{conn: conn} do
    conn = put_req_header(conn, "authorization", "Bearer secret")
    {:ok, %{conn: conn}}
  end

  describe "POST /uploads" do
    test "file url is returned", %{conn: conn} do
      upload = %Plug.Upload{path: "#{@upload_files_dir}/nalu.png", filename: "nalu.png"}

      payload = %{file: upload}

      conn = post(conn, Routes.upload_path(conn, :upload), payload)

      assert %{"url" => _url} = json_response(conn, 201)["data"]
    end

    test "params are properly validated", %{conn: conn} do
      upload = %Plug.Upload{}

      payload = %{file: upload}

      conn = post(conn, Routes.upload_path(conn, :upload), payload)

      assert %{"message" => "validation error", "errors" => errors} = json_response(conn, 422)

      assert %{"file" => %{"filename" => ["can't be blank"], "path" => ["can't be blank"]}} =
               errors
    end
  end

  describe "POST /chunk_uploads" do
    test "upload id is returned", %{conn: conn} do
      payload = %{
        fileName: "nalu.jpg",
        total_chunks: 10
      }

      conn = post(conn, Routes.upload_path(conn, :new_chunk_upload), payload)

      assert %{"uploadId" => _upload_id} = json_response(conn, 201)["data"]
    end

    test "params are properly validate", %{conn: conn} do
      payload = %{}

      conn = post(conn, Routes.upload_path(conn, :new_chunk_upload), payload)

      assert %{"message" => "validation error", "errors" => errors} = json_response(conn, 422)

      assert %{"fileName" => ["can't be blank"], "totalChunks" => ["can't be blank"]} = errors
    end
  end

  describe "MultiPart /append_chunk" do
    test "chunk is appended", %{conn: conn} do
      {:ok, id} = Oriio.Documents.new_chunk_upload("nalu.png", 8)

      upload = %Plug.Upload{path: "#{@upload_files_dir}/segmentaa", filename: "nalu.png"}

      payload = %{chunk: upload, upload_id: id, chunk_number: 1}

      conn = post(conn, Routes.upload_path(conn, :append_chunk), payload)

      assert %{"message" => "chunk was appended"} = json_response(conn, 200)["data"]
    end

    test "params are properly validated", %{conn: conn} do
      upload = %Plug.Upload{}

      payload = %{file: upload}

      conn = post(conn, Routes.upload_path(conn, :append_chunk), payload)

      assert %{"message" => "validation error", "errors" => errors} = json_response(conn, 422)

      assert %{
               "chunk" => ["can't be blank"],
               "chunkNumber" => ["can't be blank"],
               "uploadId" => ["can't be blank"]
             } = errors
    end
  end

  describe "POST /chunk_uploads/:upload_id" do
    test "file url is returned", %{conn: conn} do
      {:ok, id} = Oriio.Documents.new_chunk_upload("nalu.png", 8)

      :ok = upload_all_chunks(id, conn)

      conn = post(conn, Routes.upload_path(conn, :complete_chunk_upload, id), %{})

      assert %{"url" => _url} = json_response(conn, 201)["data"]
    end
  end

  defp upload_all_chunks(upload_id, conn) do
    document_paths =
      Path.wildcard("#{@upload_files_dir}/segment**")
      |> Enum.sort()

    for {document_path, chunk_number} <- Enum.with_index(document_paths, 1) do
      upload = %Plug.Upload{path: document_path, filename: "nalu.png"}

      payload = %{chunk: upload, upload_id: upload_id, chunk_number: chunk_number}

      conn = post(conn, Routes.upload_path(conn, :append_chunk), payload)

      json_response(conn, 200)["data"]
    end

    :ok
  end
end
