defimpl Oriio.Storages.FileStorage, for: Oriio.Storages.MockFileStorage do
  alias Oriio.Storages.FileStorage
  alias Oriio.Storages.MockFileStorage

  @type file_blob() :: FileStorage.file_blob()
  @type document_path() :: FileStorage.document_path()
  @type remote_document_path() :: FileStorage.remote_document_path()

  @spec upload_file(MockFileStorage.t(), file_blob()) :: :ok
  def upload_file(_mock, _bucket_name), do: :ok

  @spec download_file(MockFileStorage.t(), remote_document_path()) ::
          {:ok, document_path()} | {:error, term()}
  def download_file(mock, remote_document_path) do
    if mock do
      {:ok,
       %{
         mime: "ddd",
         mimetype: "ds",
         document_path: "sdsd",
         remote_document_path: remote_document_path
       }}
    else
      {:error, "failed with error"}
    end
  end
end
