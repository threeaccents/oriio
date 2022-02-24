defprotocol Mahi.Storages.FileStorage do
  @type file_blob() :: %{
          remote_file_path: binary(),
          mime: binary() | atom(),
          mimetype: binary() | atom(),
          file_path: binary()
        }

  @type file_path() :: binary()
  @type remote_file_path() :: binary()

  @spec upload_file(t(), file_blob()) :: :ok | {:error, term()}
  def upload_file(storage_engine, file_blob)

  @spec download_file(t(), remote_file_path()) :: {:ok, file_path()} | {:error, term()}
  def download_file(storage_engine, remote_location)
end
