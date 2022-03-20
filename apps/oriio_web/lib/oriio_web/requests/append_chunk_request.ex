defmodule OriioWeb.AppendChunkRequest do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:chunk_number, :integer)
    field(:upload_id, Ecto.UUID)

    embeds_one :chunk, Chunk do
      field(:path, :string)

      def changeset(model, %Plug.Upload{} = params) do
        model
        |> cast(Map.from_struct(params), ~w/path/a)
        |> validate_required(~w/path/a)
      end
    end
  end

  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/chunk_number upload_id/a)
    |> cast_embed(:chunk)
    |> validate_required(~w/chunk_number upload_id chunk/a)
    |> apply_action(:validate)
  end
end
