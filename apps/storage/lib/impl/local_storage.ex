defmodule Storage.LocalFileStorage do
  @behaviour Storage

  def save(file_key, file_path) do
    File.mkdir_p!(storage_dir())

    local_file_path = Path.join(storage_dir(), file_key)

    with {:ok, _bytes} <- File.copy(file_path, local_file_path) do
      :ok
    end
  end

  def get(file_key) do
    local_file_path = Path.join(storage_dir(), file_key)

    file_path = Briefly.create!()

    with {:ok, _bytes} <- File.copy(local_file_path, file_path) do
      {:ok, file_path}
    end
  end

  defp storage_dir, do: Application.get_env(:oriio, :storage)[:local_storage_dir] || File.cwd!()
end
