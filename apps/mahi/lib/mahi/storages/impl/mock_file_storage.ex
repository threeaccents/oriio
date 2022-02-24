defimpl Mahi.Storages.FileStorage, for: Mahi.Storages.MockFileStorage do
  alias Mahi.Storages.FileStorage
  alias Mahi.Storages.MockFileStorage

  @type file_blob() :: FileStorage.file_blob()
  @type file_path() :: FileStorage.file_path()
  @type remote_file_path() :: FileStorage.remote_file_path()

  @spec upload_file(MockFileStorage.t(), file_blob()) :: :ok
  def upload_file(_mock, _bucket_name), do: :ok

  @spec download_file(MockFileStorage.t(), remote_file_path()) ::
          {:ok, file_path()} | {:error, term()}
  def download_file(mock, remote_file_path) do
    if mock do
      {:ok, %{mime: "ddd", mimetype: "ds", file_path: "sdsd", remote_file_path: remote_file_path}}
    else
      {:error, "failed with error"}
    end
  end
end
