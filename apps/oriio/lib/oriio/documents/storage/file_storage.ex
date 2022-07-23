defprotocol Oriio.Storages.FileStorage do
  @type file_info() :: %{
          remote_document_path: binary(),
          mime: binary() | atom(),
          mimetype: binary() | atom(),
          document_path: binary()
        }

  @type document_path() :: binary()
  @type remote_document_path() :: binary()

  @spec upload_file(t(), file_info()) :: :ok | {:error, term()}
  def upload_file(storage_engine, file_info)

  @spec download_file(t(), remote_document_path()) :: {:ok, document_path()} | {:error, term()}
  def download_file(storage_engine, remote_location)
end
