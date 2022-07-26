defmodule WebApi.UploadRequest do
  @moduledoc """
  Validation parameters for uploading a file.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type file() :: %{
          filename: String.t(),
          path: String.t()
        }

  @type t() :: %__MODULE__{
          file: file()
        }

  embedded_schema do
    embeds_one :file, File do
      field(:filename, :string)
      field(:path, :string)

      @spec changeset(map(), map()) :: map()

      def changeset(model, %Plug.Upload{} = params) do
        model
        |> cast(Map.from_struct(params), ~w/filename path/a)
        |> validate_required(~w/filename path/a)
      end
    end
  end

  @spec from_params(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_params(params) do
    %__MODULE__{}
    |> cast(params, [])
    |> cast_embed(:file)
    |> validate_required(~w/file/a)
    |> apply_action(:validate)
  end
end
