defmodule OriioWeb.ServeFileRequest do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:timestamp, :utc_datetime)
    field(:file_name, :string)
    field(:height, :integer)
    field(:width, :integer)
    field(:crop, :boolean)
  end

  def from_params(params) do
    %__MODULE__{}
    |> cast(params, ~w/timestamp file_name height width crop/a)
    |> validate_required(~w/timestamp file_name/a)
    |> apply_action(:validate)
  end
end
