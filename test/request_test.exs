defmodule StarkCoreTest.Request do
  alias StarkCore.Utils.Request
  alias StarkCore.Utils.JSON
  alias StarkCore.Project
  use ExUnit.Case

  @tag :fetch_get
  test "fetch balance resource" do
    {:ok, response} = Request.fetch(
      :bank,
      :get,
      "balance",
      %{
        sdk_version: "1.0.0",
        api_version: "v2",
        query: %{},
        prefix: "Joker",
        timeout: 15,
        payload: nil,
        language: "us-EN"
      }
    )
    response_string = to_string(response)
    response_decoded = JSON.decode!(response_string)
    balances = response_decoded["balances"]
    first_balance = List.first(balances)
    amount = first_balance["amount"]

    assert !is_nil(amount)
  end


  test "fetch balance resource using fetch_raw" do
    {:ok, %{headers: headers, content: content, status_code: status_code}} = Request.fetch_raw(
      :bank,
      :get,
      "balance",
      %{
        sdk_version: "1.0.0",
        api_version: "v2",
        query: %{},
        prefix: "Joker",
        timeout: 15,
        payload: nil,
        language: "us-EN"
      }
    )

    response_string = to_string(content)
    response_decoded = JSON.decode!(response_string)
    balances = response_decoded["balances"]
    first_balance = List.first(balances)
    amount = first_balance["amount"]

    assert !is_nil(amount)
    assert !is_nil(headers)
    assert status_code == 200
  end


  @tag :fetch_get
  test "fetch balance with custom user" do
    {:ok, proj} = Application.fetch_env(:starkcore, :project)
    custom_user = Project.validate(
      proj[:environment],
      proj[:id],
      proj[:private_key]
    )

    {:ok, response} = Request.fetch(
      :bank,
      :get,
      "balance",
      %{
        sdk_version: "1.0.0",
        api_version: "v2",
        query: %{},
        prefix: "Joker",
        timeout: 15,
        payload: nil,
        language: "us-EN",
        user: custom_user
      }
    )
    response_string = to_string(response)
    response_decoded = JSON.decode!(response_string)
    balances = response_decoded["balances"]
    first_balance = List.first(balances)
    amount = first_balance["amount"]

    assert !is_nil(amount)
  end


  @tag :fetch_get
  test "fetch invoices with limit query" do
    {:ok, response} = Request.fetch(
      :bank,
      :get,
      "invoice",
      %{
        sdk_version: "1.0.0",
        api_version: "v2",
        query: [
          limit: 1
        ],
        prefix: "Joker",
        timeout: 15,
        payload: nil,
        language: "us-EN"
      }
    )
    response_string = to_string(response)
    response_decoded = JSON.decode!(response_string)

    assert(Enum.count(response_decoded["invoices"]) == 1, "Should only have 1 invoice")
  end


  @tag :fetch_get_fail
  test "Fail to fetch invalid path" do
    {:error, response} = Request.fetch(
      :bank,
      :get,
      "balancex",
      %{
        sdk_version: "1.0.0",
        api_version: "v2",
        query: nil,
        prefix: "Joker",
        timeout: 15,
        payload: nil,
        language: "us-EN"
      }
    )

    assert(List.first(response).code == "routeNotFound")
  end


  @tag :fetch_get_fail
  test "Fail to fetch with invalid host" do
    service = :banx
    {:error, message} = Request.fetch(
      service,
      :get,
      "balance",
      %{}
    )

    assert(message == "service #{service} is invalid")
  end


  test "fetch :post invoice" do
    {:ok, response} = Request.fetch(
      :bank,
      :post,
      "invoice",
      %{
        sdk_version: "1.0.0",
        api_version: "v2",
        query: nil,
        prefix: "Joker",
        timeout: 15,
        language: "us-EN",
        payload: %{
          invoices: [
            %{
              amount: 10000,
              taxId: "45.059.493/0001-73",
              name: "core-elixir invoice creation test by fetch"
            }
          ]
        }
      }
    )

    response_string = to_string(response)
    %{"invoices" => invoices, "message" => _message} = JSON.decode!(response_string)
    first_invoice = List.first(invoices)
    amount = first_invoice["amount"]
    assert !is_nil(amount)

  end


end
