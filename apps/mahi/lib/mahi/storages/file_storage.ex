defprotocol Mahi.Storages.FileStorage do
  @type file_blob() :: %{
          remote_location: binary(),
          mime: binary() | atom(),
          mimetype: binary() | atom(),
          file_path: binary()
        }

  @type file_path :: binary()
  @type remote_location :: binary()

  @spec upload_file(t(), file_blob()) :: :ok | {:error, term()}
  def upload_file(storage_engine, file_blob)

  @spec download_file(t(), remote_location()) :: {:ok, file_path()} | {:error, term()}
  def download_file(storage_engine, remote_location)
end
