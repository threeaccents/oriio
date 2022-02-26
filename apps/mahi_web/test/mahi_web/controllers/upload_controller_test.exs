defmodule MahiWeb.PageControllerTest do
  use MahiWeb.ConnCase

  # move fixtures to the root to share between both.
  # @upload_files_dir "#{__DIR__}/../../../../mahi/test/fixtures/uploads"

  test "yolo" do
    assert true == true
  end

  # describe "POST /uploads" do
  #   test "file url is returned", %{conn: conn} do
  #     upload = %Plug.Upload{path: "#{@upload_files_dir}/nalu.png", filename: "nalu.png"}

  #     payload = %{file: upload}

  #     conn = post(conn, Routes.upload_path(conn, :upload), payload)

  #     assert %{"url" => _url} = json_response(conn, 201)["data"]
  #   end
  # end

  # describe "POST /chunk_uploads" do
  #   test "upload id is returned", %{conn: conn} do
  #     payload = %{
  #       file_name: "nalu.jpg",
  #       total_chunks: 10
  #     }

  #     conn = post(conn, Routes.upload_path(conn, :new_chunk_upload), payload)

  #     assert %{"uploadId" => _upload_id} = json_response(conn, 201)["data"]
  #   end

  #   test "file name is required", %{conn: conn} do
  #     payload = %{
  #       total_chunks: 10
  #     }

  #     conn = post(conn, Routes.upload_path(conn, :new_chunk_upload), payload)

  #     assert %{"fileName" => ["is required"]} = json_response(conn, 422)["message"]
  #   end
  # end

  # describe "MultiPart /append_chunk" do
  #   test "chunk is appended", %{conn: conn} do
  #     id = Mahi.Uploads.new_chunk_upload("nalu.png", 8)

  #     upload = %Plug.Upload{path: "#{@upload_files_dir}/segmentaa", filename: "nalu.png"}

  #     payload = %{chunk: upload, upload_id: id, chunk_number: 1}

  #     conn = post(conn, Routes.upload_path(conn, :append_chunk), payload)

  #     assert %{"message" => "chunk was appended"} = json_response(conn, 200)["data"]
  #   end

  #   test "validation", %{conn: conn} do
  #     id = Mahi.Uploads.new_chunk_upload("nalu.png", 8)

  #     upload = %Plug.Upload{path: "#{@upload_files_dir}/segmentaa", filename: "nalu.png"}

  #     payload = %{chunk: upload, upload_id: id}

  #     conn = post(conn, Routes.upload_path(conn, :append_chunk), payload)

  #     assert %{"chunkNumber" => ["is required"]} = json_response(conn, 422)["message"]
  #   end
  # end

  # describe "POST /chunk_uploads/:upload_id" do
  #   test "file url is returned", %{conn: conn} do
  #     id = Mahi.Uploads.new_chunk_upload("nalu.png", 8)

  #     :ok = upload_all_chunks(id, conn)

  #     conn = post(conn, Routes.upload_path(conn, :complete_chunk_upload, id), %{})

  #     assert %{"url" => _url} = json_response(conn, 201)["data"]
  #   end

  #   test "validation", %{conn: conn} do
  #     # id = Mahi.Uploads.new_chunk_upload("nalu.png", 8)

  #     # upload = %Plug.Upload{path: "#{@upload_files_dir}/segmentaa", filename: "nalu.png"}

  #     # payload = %{chunk: upload, upload_id: id}

  #     # conn = post(conn, "/append_chunk", payload)

  #     # assert %{"chunkNumber" => ["is required"]} = json_response(conn, 422)["message"]
  #   end
  # end

  # defp upload_all_chunks(upload_id, conn) do
  #   document_paths =
  #     Path.wildcard("#{@upload_files_dir}/segment**")
  #     |> Enum.sort()

  #   for {document_path, chunk_number} <- Enum.with_index(document_paths, 1) do
  #     upload = %Plug.Upload{path: document_path, filename: "nalu.png"}

  #     payload = %{chunk: upload, upload_id: upload_id, chunk_number: chunk_number}

  #     conn = post(conn, Routes.upload_path(conn, :append_chunk), payload)

  #     json_response(conn, 200)["data"]
  #   end

  #   :ok
  # end
end
