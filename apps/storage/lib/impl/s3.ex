defmodule Storage.S3 do
  @behaviour Storage

  alias ExAws.S3

  require Logger

  def save(file_key, file_path) do
    file_path
    |> S3.Upload.stream_file()
    |> S3.upload(bucket(), file_key)
    |> ExAws.request(
      access_key_id: access_key(),
      secret_access_key: secret_key(),
      region: region()
    )
    |> case do
      {:ok, _resp} ->
        :ok

      {:error, reason} ->
        Logger.error("failed uploading file. reason: #{inspect(reason)}")
        {:error, :failed_to_upload_file}
    end
  end

  def get(file_key) do
    file_path = Briefly.create!()

    bucket()
    |> S3.download_file(file_key, file_path)
    |> ExAws.request(
      access_key_id: access_key(),
      secret_access_key: secret_key(),
      region: region()
    )
    |> case do
      {:ok, _} ->
        {:ok, file_path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp bucket, do: ""
  defp access_key, do: ""
  defp region, do: ""
  defp secret_key, do: ""
end
