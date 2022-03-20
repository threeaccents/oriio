defmodule OriioWeb.UploadRequest do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    embeds_one :file, File do
      field(:filename, :string)
      field(:path, :string)

      def changeset(model, %Plug.Upload{} = params) do
        model
        |> cast(Map.from_struct(params), ~w/filename path/a)
        |> validate_required(~w/filename path/a)
      end
    end
  end

  def from_params(params) do
    %__MODULE__{}
    |> cast(params, [])
    |> cast_embed(:file)
    |> validate_required(~w/file/a)
    |> apply_action(:validate)
  end
end
