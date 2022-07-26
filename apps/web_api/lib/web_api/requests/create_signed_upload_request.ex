defmodule WebApi.CreateSignedUploadRequest do
  @moduledoc """
  Validation parameters for creating a singed upload.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %{
          upload_type: :default | :chunked
        }

  embedded_schema do
    field(:upload_type, Ecto.Enum, values: ~w/default chunked/a)
  end

  @spec from_params(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/upload_type/a)
    |> validate_required(~w/upload_type/a)
    |> apply_action(:validate)
  end
end
