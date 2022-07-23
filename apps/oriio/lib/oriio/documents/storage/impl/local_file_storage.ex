defimpl Oriio.Storages.FileStorage, for: Oriio.Storages.LocalFileStorage do
  alias Oriio.Storages.LocalFileStorage
  alias Oriio.Storages.FileStorage

  require Logger

  @type file_info() :: FileStorage.file_info()
  @type document_path() :: FileStorage.document_path()
  @type remote_document_path() :: FileStorage.remote_document_path()

  @spec upload_file(LocalFileStorage.t(), file_info()) ::
          :ok | {:error, :failed_to_upload_file}
  def upload_file(_local, file_info) do
    %{
      document_path: document_path,
      remote_document_path: remote_document_path
    } = file_info

    with {:ok, _bytes} <- File.copy(document_path, remote_document_path) do
      :ok
    end
  end

  @spec download_file(LocalFileStorage.t(), remote_document_path()) ::
          {:ok, document_path()} | {:error, term()}
  def download_file(_local, remote_document_path) do
    dir = Briefly.create!(directory: true)
    document_path = Path.join(dir, file_name(remote_document_path))

    with {:ok, _bytes} <- File.copy(remote_document_path, document_path) do
      {:ok, document_path}
    end
  end

  defp file_name(document_path) do
    document_path
    |> String.split("/")
    |> List.last()
  end
end
