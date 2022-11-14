defmodule Banzai do
  @moduledoc """
  Banzai allows us to create actions based on the token pattern.
  """

  require Logger

  @type meta() :: %{
          id: Ecto.UUID.t(),
          transaction: boolean()
        }

  @type t() :: %__MODULE__{
          __META__: meta(),
          token: map() | struct(),
          funcs: list(function()),
          # convert to proper defexception error
          error: term() | nil
        }

  defstruct token: %{}, funcs: [], error: nil, __META__: %{}

  defmacro __using__(_opts) do
    require Logger

    quote generated: true do
      alias Ecto.Changeset
      import Ecto.Changeset
      use Ecto.Schema
      @behaviour Banzai

      import Banzai,
        only: [
          run: 1,
          step: 2,
          new: 2,
          new: 3
        ]
    end
  end

  @doc """
  Execute the event
  """
  @callback perform(map()) :: {:ok, term()} | {:error, term()}

  @spec new(map() | struct(), map(), Keyword.t()) :: t()
  def new(token, initial_state \\ %{}, opts \\ []) do
    %__MODULE__{
      __META__: %{
        id: Ecto.UUID.generate(),
        transaction: Keyword.get(opts, :transaction, false)
      },
      token: Map.merge(token, initial_state),
      funcs: [],
      error: nil
    }
  end

  @spec step(t(), function(), Keyword.t()) :: t()
  def step(action = %__MODULE__{funcs: funcs}, func, _opts \\ []) do
    %__MODULE__{
      action
      | funcs: [func | funcs]
    }
  end

  defp run_step(action = %__MODULE__{error: error}, _) when error != nil, do: action

  defp run_step(action, func) do
    case func.(action.token) do
      {:ok, updated_token} ->
        %__MODULE__{action | token: updated_token}

      {:error, reason} ->
        %__MODULE__{action | error: reason}

      _ ->
        # better error reporting
        throw("BANZAI response must be of type {:ok, term} | {:error, term} #{inspect(func)}")
    end
  end

  @spec run(t()) :: {:ok, t()} | {:error, term()}
  def run(action = %__MODULE__{}) do
    transaction = action.__META__.transaction

    if transaction do
      repo().transact(fn ->
        execute(action)
      end)
    else
      execute(action)
    end
  end

  defp execute(action = %__MODULE__{funcs: funcs}) do
    funcs = Enum.reverse(funcs)

    Enum.reduce(funcs, action, fn func, acc ->
      run_step(acc, func)
    end)
    |> case do
      %__MODULE__{error: reason} when reason != nil -> {:error, reason}
      %__MODULE__{token: token} -> {:ok, token}
    end
  end

  defp repo do
    Application.get_env(:banzai, :repo)
  end
end
