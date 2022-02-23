defmodule MahiWeb.PageControllerTest do
  use MahiWeb.ConnCase

  # move fixtures to the root to share between both.
  @upload_files_dir "#{__DIR__}/../../../mahi/lib/test/fixtures/uploads"

  describe "POST /chunk_uploads" do
    test "upload id is returned", %{conn: conn} do
      payload = %{
        file_name: "nalu.jpg",
        total_chunks: 10
      }

      conn = post(conn, Routes.upload_path(conn, :new_chunk_upload), payload)

      assert %{"uploadId" => _upload_id} = json_response(conn, 201)["data"]
    end

    test "file name is required", %{conn: conn} do
      payload = %{
        total_chunks: 10
      }

      conn = post(conn, Routes.upload_path(conn, :new_chunk_upload), payload)

      assert %{"fileName" => ["is required"]} = json_response(conn, 422)["message"]
    end
  end

  describe "MultiPart /append_chunk" do
    test "chunk is appended", %{conn: conn} do
      id = Mahi.Uploads.new_chunk_upload("nalu.png", 8)

      upload = %Plug.Upload{path: "#{@upload_files_dir}/segmentaa", filename: "nalu.png"}

      payload = %{chunk: upload, upload_id: id, chunk_number: 1}

      conn = post(conn, "/append_chunk", payload)

      assert %{"message" => "chunk was appended"} = json_response(conn, 200)["data"]
    end

    test "validation", %{conn: conn} do
      id = Mahi.Uploads.new_chunk_upload("nalu.png", 8)

      upload = %Plug.Upload{path: "#{@upload_files_dir}/segmentaa", filename: "nalu.png"}

      payload = %{chunk: upload, upload_id: id}

      conn = post(conn, "/append_chunk", payload)

      assert %{"chunkNumber" => ["is required"]} = json_response(conn, 422)["message"]
    end
  end
end
