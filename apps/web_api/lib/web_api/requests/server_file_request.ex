defmodule WebApi.ServeFileRequest do
  @moduledoc """
  Validation parameters for serving a file.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{
          timestamp: DateTime.t(),
          file_name: String.t(),
          height: integer(),
          width: integer(),
          crop: boolean()
        }

  embedded_schema do
    field(:timestamp, :utc_datetime)
    field(:file_name, :string)
    field(:height, :integer)
    field(:width, :integer)
    field(:crop, :boolean)
  end

  @spec from_params(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/timestamp file_name height width crop/a)
    |> validate_required(~w/timestamp file_name/a)
    |> apply_action(:validate)
  end
end
