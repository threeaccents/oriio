defimpl Mahi.Storages.FileStorage, for: Mahi.Storages.S3FileStorage do
  alias Mahi.Storages.S3FileStorage
  alias Mahi.Storages.FileStorage
  alias ExAws.S3

  require Logger

  @type file_blob() :: FileStorage.file_blob()
  @type file_path() :: StorFileStorageageEngine.file_path()
  @type remote_location() :: FileStorage.remote_location()

  @spec upload_file(S3FileStorage.t(), file_blob()) ::
          :ok | {:error, :failed_to_upload_file}
  def upload_file(s3, file_blob) do
    %{file_path: file_path, remote_location: remote_location, mime: mime, mimetype: mimetype} =
      file_blob

    object_opts = [content_type: mime <> "/" <> mimetype]

    file_path
    |> S3.Upload.stream_file()
    |> S3.upload(s3.bucket, remote_location, object_opts)
    |> ExAws.request(
      access_key_id: s3.access_key,
      secret_access_key: s3.secret_key,
      region: s3.region
    )
    |> case do
      {:ok, _resp} ->
        :ok

      {:error, reason} ->
        Logger.error("failed uploading file. reason: #{inspect(reason)}")
        {:error, :failed_to_upload_file}
    end
  end

  @spec download_file(S3FileStorage.t(), remote_location()) ::
          {:ok, file_path()} | {:error, term()}
  def download_file(s3, remote_location) do
    file_path = Briefly.create!()

    s3.bucket
    |> S3.download_file(remote_location, file_path)
    |> ExAws.request(
      access_key_id: s3.access_key,
      secret_access_key: s3.secret_key,
      region: s3.region
    )
    |> case do
      {:ok, _} ->
        {:ok, file_path}

      {:error, reason} ->
        {:error, reason}
    end
  end
end