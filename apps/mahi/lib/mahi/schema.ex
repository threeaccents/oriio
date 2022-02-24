defmodule Mahi.Schema do
  @moduledoc """
  Schema macto to help set the primary keys properly.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      # @derive {Inspect, except: [:password, :storage_secret_key]}
    end
  end
end
