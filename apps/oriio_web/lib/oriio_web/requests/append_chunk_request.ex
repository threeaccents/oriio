defmodule OriioWeb.AppendChunkRequest do
  @moduledoc """
  Validation parameters for appending a chunk to the chunk upload.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type chunk() :: %{
          path: String.t()
        }

  @type t() :: %__MODULE__{
          chunk_number: integer(),
          upload_id: Ecto.UUID.t(),
          chunk: chunk()
        }

  embedded_schema do
    field(:chunk_number, :integer)
    field(:upload_id, Ecto.UUID)

    embeds_one :chunk, Chunk do
      field(:path, :string)

      @spec changeset(map(), map()) :: map()

      def changeset(model, %Plug.Upload{} = params) do
        model
        |> cast(Map.from_struct(params), ~w/path/a)
        |> validate_required(~w/path/a)
      end
    end
  end

  @spec from_params(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}

  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/chunk_number upload_id/a)
    |> cast_embed(:chunk)
    |> validate_required(~w/chunk_number upload_id chunk/a)
    |> apply_action(:validate)
  end
end
