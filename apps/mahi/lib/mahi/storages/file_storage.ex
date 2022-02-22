defprotocol Mahi.Storages.FileStorage do
  @type file_blob() :: %{
          remote_location: String.t(),
          mime: String.t() | atom(),
          mimetype: String.t() | atom(),
          file_path: String.t()
        }

  @type file_path :: String.t()
  @type remote_location :: String.t()

  @spec upload_file(t(), file_blob()) :: :ok | {:error, term()}
  def upload_file(storage_engine, file_blob)

  @spec download_file(t(), remote_location()) :: {:ok, file_path()} | {:error, term()}
  def download_file(storage_engine, remote_location)
end
