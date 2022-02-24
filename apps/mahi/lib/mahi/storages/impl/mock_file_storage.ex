defimpl Mahi.Storages.FileStorage, for: Mahi.Storages.MockFileStorage do
  alias Mahi.Storages.FileStorage
  alias Mahi.Storages.MockFileStorage

  @spec upload_file(MockFileStorage.t(), term()) :: :ok
  def upload_file(_mock, _bucket_name), do: :ok

  @spec download_file(MockFileStorage.t(), binary()) ::
          {:ok, FileStorage.file_blob()} | {:error, :no}
  def download_file(mock, remote_location) do
    if mock do
      {:ok, %{mime: "ddd", mimetype: "ds", file_path: "sdsd", remote_location: remote_location}}
    else
      {:error, :no}
    end
  end
end
