defmodule Mahi.SignedUrlTest do
  use ExUnit.Case, async: true

  alias Mahi.SignedUrl

  alias Mahi.Utils

  test "generates a signed url" do
    url = SignedUrl.genrate("hello world")

    assert {:ok, _url} = Utils.is_valid_url?(url)

    assert [base_url, key] = String.split(url, "?key=")

    assert {:ok, _url} = Utils.is_valid_url?(base_url)

    assert [_protected, _payload, _signature] = String.split(key, ".")
  end
end
