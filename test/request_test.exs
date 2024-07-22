defmodule StarkCoreTest.Request do
  alias StarkCore.Utils.Request
  alias StarkCore.Utils.JSON
  use ExUnit.Case

  @doc false
  @tag :fetch
  test "fetch balance resource" do
    {:ok, response} = Request.fetch(:bank, :get, "balance", [])
    response_string = to_string(response)
    response_decoded = JSON.decode!(response_string)
    balances = response_decoded["balances"]
    first_balance = List.first(balances)
    amount = first_balance["amount"]

    assert !is_nil(amount)
  end

  test "fetch invoice list with filters" do
    {:ok, response} = Request.fetch(:bank, :get, "invoice", [query: %{limit: 2}])
    response_string = to_string(response)
    response_decoded = JSON.decode!(response_string)
    invoices = response_decoded["invoices"]
    first_invoice = List.first(invoices)
    amount = first_invoice["amount"]

    assert !is_nil(amount)
  end

  test "fetch :post invoice" do
    {:ok, response} = Request.fetch(
      :bank, :post, "invoice",
      payload: %{
        invoices: [
          %{
            amount: 10000,
            taxId: "45.059.493/0001-73",
            name: "core-elixir invoice creation test by fetch"
          }
        ]
      }
    )

    response_string = to_string(response)
    %{"invoices" => invoices, "message" => _message} = JSON.decode!(response_string)
    first_invoice = List.first(invoices)
    amount = first_invoice["amount"]
    assert !is_nil(amount)

  end
end
