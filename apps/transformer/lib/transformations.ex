defmodule Transformer.Transformations do
  @moduledoc """
  Struct of all the possible image transformations with corresponding values
  """
  use Ecto.Schema

  @type angle() :: float()

  @type direction() :: "vertical" | "horizontal"

  @type format() :: "jpg" | "jpeg" | "png" | "webp"

  @type t() :: %__MODULE__{
          width: integer(),
          height: integer(),
          black_n_white: boolean(),
          flip: direction(),
          rotate: angle(),
          format: format()
        }

  @primary_key false
  embedded_schema do
    field(:width, :string)
    field(:height, :string)
    field(:black_n_white, :string)
    field(:flip, :string)
    field(:rotate, :integer)
    field(:format, :string)
  end
end
