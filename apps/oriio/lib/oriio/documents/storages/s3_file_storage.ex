defmodule Oriio.Storages.S3FileStorage do
  @moduledoc """
  S3 config struct. This struct is passed into the FileStorage protocol and implemented in the
  S3FileStorage IMPL
  """

  use Oriio.Schema

  @type t() :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :access_key, :string
    field :secret_key, :string
    field :bucket, :string
    field :region, :string
  end
end
