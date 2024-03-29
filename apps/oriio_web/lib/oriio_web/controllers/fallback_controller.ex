defmodule OriioWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.
  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use OriioWeb, :controller

  @type conn() :: Plug.Conn.t()

  @spec call(conn(), {:error, term()} | {:error, term(), term()}) :: conn()
  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(OriioWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(OriioWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :invalid_credentials}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(OriioWeb.ErrorView)
    |> render("error.json", %{error: {:error, :invalid_credentials}})
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(OriioWeb.ErrorView)
    |> render("error.json", %{error: {:error, :unauthorized}})
  end

  def call(conn, {:error, :unauthorized, _msg}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(OriioWeb.ErrorView)
    |> render("error.json", %{error: {:error, :unauthorized}})
  end

  def call(conn, {:error, msg}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(OriioWeb.ErrorView)
    |> render("error.json", %{message: msg})
  end
end
