defmodule StarkCoreTestURL do
  alias StarkCore.Utils.URL
  use ExUnit.Case

  @tag :add_query
  test "Should add query to url" do
    url_with_query = URL.get_url(
      :bank,
      :sandbox,
      "v2",
      "invoice",
      limit: 100,
      status: "paid"
    )

    assert url_with_query == "https://sandbox.api.starkbank.com/v2/invoice?limit=100&status=paid"
  end

  test "Should get url without query" do
    url_with_query = URL.get_url(
      :bank,
      :sandbox,
      "v2",
      "invoice",
      []
    )

    assert url_with_query == "https://sandbox.api.starkbank.com/v2/invoice"
  end
end
