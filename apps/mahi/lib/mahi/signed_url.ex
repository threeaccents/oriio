defmodule Mahi.SignedUrl do
  alias Plug.Crypto

  @type auth_token() :: binary()

  @signed_url_salt "mahi_is_the_bees_knees"

  @spec generate(any()) :: auth_token()
  def generate(payload) do
    token = Crypto.sign(auth_secret_key(), @signed_url_salt, payload, max_age: 1000)

    base_file_url() <> "?key=#{token}"
  end

  @spec verify(auth_token()) :: :ok | {:error, term()}
  def verify(token) do
    case Crypto.verify(auth_secret_key(), @signed_url_salt, token) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp auth_secret_key, do: Application.get_env(:mahi, :auth_secret_key)

  defp base_file_url, do: Application.get_env(:mahi, :base_file_url, "https://localhost:4000")
end
