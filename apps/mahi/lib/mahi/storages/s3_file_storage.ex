defmodule Mahi.Storages.S3FileStorage do
  use Mahi.Schema

  @type t() :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :access_key, :string
    field :secret_key, :string
    field :bucket, :string
    field :region, :string
  end
end
