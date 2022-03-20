defmodule OriioWeb.CompleteChunkUploadRequest do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:upload_id, Ecto.UUID)
  end

  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/upload_id/a)
    |> validate_required(~w/upload_id/a)
    |> apply_action(:validate)
  end
end
