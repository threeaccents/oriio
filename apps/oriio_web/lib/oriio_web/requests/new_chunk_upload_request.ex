defmodule OriioWeb.NewChunkUploadRequest do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:file_name, :string)
    field(:total_chunks, :integer)
  end

  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/file_name total_chunks/a)
    |> validate_required(~w/file_name total_chunks/a)
    |> apply_action(:validate)
  end
end
