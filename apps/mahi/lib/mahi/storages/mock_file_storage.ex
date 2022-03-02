defmodule Oriio.Storages.MockFileStorage do
  @moduledoc """
  Mock config for FileStorage.
  It used primarily for testing.
  """
  @type t() :: %__MODULE__{}

  defstruct mock: true
end
