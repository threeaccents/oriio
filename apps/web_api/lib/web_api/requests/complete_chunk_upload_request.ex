defmodule WebApi.CompleteChunkUploadRequest do
  @moduledoc """
  Validation parameters for completing a chunk upload.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{
          upload_id: Ecto.UUID.t()
        }

  embedded_schema do
    field(:upload_id, Ecto.UUID)
  end

  @spec from_params(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/upload_id/a)
    |> validate_required(~w/upload_id/a)
    |> apply_action(:validate)
  end
end
