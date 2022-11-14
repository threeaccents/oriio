defmodule Uploader.UploadFileAction do
  use Banzai

  alias __MODULE__.Metadata

  embedded_schema do
    # inputs
    field(:file_name, :string)
    field(:file_path, :string)

    # internal token fields
    embeds_one :metadata, Metadata do
      field(:mime, :string)
      field(:mime_type, :string)
      field(:size, :integer)
    end
  end

  def perform(params) do
    %__MODULE__{}
    |> new(params)
    |> step(&generate_file_metadata/1)
    |> step(&store_file/1)
  end

  defp generate_file_metadata(action = %__MODULE__{}) do
    %__MODULE__{file_path: file_path} = action

    {mime, mime_type} = ExMime.check_magic_bytes(file_path)

    %{size: size} = File.stat!(file_path)

    metadata = %{
      mime: mime,
      mime_type: mime_type,
      size: size
    }

    %__MODULE__{action | metadata: metadata}
  end

  defp store_file(action = %__MODULE__{}) do
    action
  end
end
