defmodule Mahi.Utils do
  def is_valid_url?(url) when is_binary(url) and byte_size(url) > 0 do
    url
    |> validate_protocol
    |> validate_host
    |> validate_uri
  end

  def is_valid_url?(nil), do: {:ok, nil}

  def is_valid_url?(_), do: :error

  defp validate_protocol("http://" <> rest = url) do
    {url, rest}
  end

  defp validate_protocol("https://" <> rest = url) do
    {url, rest}
  end

  defp validate_protocol(_), do: :error

  defp validate_host(:error), do: :error

  defp validate_host({url, rest}) do
    [domain | uri] = String.split(rest, "/")

    domain =
      case String.split(domain, ":") do
        # ipv6
        [_, _, _, _, _, _, _, _] -> domain
        [domain, _port] -> domain
        _ -> domain
      end

    erl_host = String.to_charlist(domain)

    if :inet_parse.domain(erl_host) or
         match?({:ok, _}, :inet_parse.ipv4strict_address(erl_host)) or
         match?({:ok, _}, :inet_parse.ipv6strict_address(erl_host)) do
      {url, Enum.join(uri, "/")}
    else
      :error
    end
  end

  defp validate_uri(:error), do: :error

  defp validate_uri({url, uri}) do
    if uri == URI.encode(uri) |> URI.decode() do
      {:ok, url}
    else
      :error
    end
  end
end
