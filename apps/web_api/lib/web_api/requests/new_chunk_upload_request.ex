defmodule WebApi.NewUploadRequest do
  @moduledoc """
  Validation parameters for creating a new chunk uplod.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{
          file_name: String.t(),
          total_chunks: integer()
        }

  embedded_schema do
    field(:file_name, :string)
    field(:total_chunks, :integer)
  end

  @spec from_params(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/file_name total_chunks/a)
    |> validate_required(~w/file_name total_chunks/a)
    |> apply_action(:validate)
  end
end
