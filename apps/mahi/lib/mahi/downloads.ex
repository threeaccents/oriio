defmodule Mahi.Downloads do
  alias Mahi.Storages.S3FileStorage
  alias Mahi.Storages.MockFileStorage
  alias Mahi.Storages.FileStorage

  @type remote_file_location() :: binary()
  @type file_path() :: binary()

  @spec download(remote_file_location()) :: {:ok, file_path()} | {:error, term()}
  def download(remote_file_location) do
    FileStorage.download_file(storage_engine(), remote_file_location)
  end

  defp storage_engine do
    storage_engine =
      Application.get_env(:mahi, :file_storage)[:storage_engine] || %S3FileStorage{}

    case storage_engine do
      S3FileStorage ->
        %S3FileStorage{
          access_key: Application.get_env(:mahi, :file_storage)[:access_key],
          secret_key: Application.get_env(:mahi, :file_storage)[:secret_key],
          region: Application.get_env(:mahi, :file_storage)[:region],
          bucket: Application.get_env(:mahi, :file_storage)[:bucket]
        }

      MockFileStorage ->
        %MockFileStorage{}
    end
  end
end
