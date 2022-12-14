defmodule Storage do
  @type file_path() :: String.t()
  @type file_key() :: String.t()

  @callback save(file_key(), file_key()) :: :ok
  @callback get(file_key()) :: {:ok, file_path()} | {:error, term()}

  def save(file_key, file_path), do: impl().save(file_key, file_path)

  def get(file_key), do: impl().get(file_key)

  defp impl,
    do: Application.get_env(:oriio, :storage)[:storage_engine] || Storage.LocalFileStorage
end
