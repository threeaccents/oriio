defmodule Oriio.Storages.LocalFileStorage do
  @moduledoc """
  Local config struct. This struct is passed into the FileStorage protocol and implemented in the
  LocalFileStorage IMPL
  """

  use Oriio.Schema

  @type t() :: %__MODULE__{}

  @primary_key false
  embedded_schema do
  end
end
