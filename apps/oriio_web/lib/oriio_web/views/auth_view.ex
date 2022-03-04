defmodule OriioWeb.AuthView do
  use OriioWeb, :view
  alias OriioWeb.AuthView

  def render("index.json", %{tokens: tokens}) do
    data = %{data: render_many(tokens, AuthView, "token.json", as: :token)}
    to_camel_case(data)
  end

  def render("show.json", %{token: token}) do
    data = %{data: render_one(token, AuthView, "token.json", as: :token)}
    to_camel_case(data)
  end

  def render("token.json", %{token: token}) do
    %{
      token: token
    }
  end
end
