defmodule StarkBank.Balance do
  alias __MODULE__, as: Balance
  alias StarkCore.Utils.Check

  defstruct [:id, :amount, :currency, :updated]
  def resource() do
    {
      "Balance",
      &resource_maker/1
    }
  end

  def non_existent_resource() do
    {
      "NonExistentResource",
      &resource_maker/1
    }
  end

  @doc false
  def resource_maker(json) do
    %Balance{
      id: json[:id],
      amount: json[:amount],
      currency: json[:currency],
      updated: json[:updated] |> Check.datetime()
    }
  end
end

defmodule StarkBank.Invoice do
  alias __MODULE__, as: Invoice
  alias StarkCore.Utils.Check

  @enforce_keys [
    :amount,
    :tax_id,
    :name,
  ]
  defstruct [
    :amount,
    :due,
    :tax_id,
    :name,
    :expiration,
    :fine,
    :interest,
    :discounts,
    :tags,
    :descriptions,
    :pdf,
    :link,
    :nominal_amount,
    :fine_amount,
    :interest_amount,
    :discount_amount,
    :id,
    :brcode,
    :status,
    :fee,
    :transaction_ids,
    :created,
    :updated
  ]

  @type t() :: %__MODULE__{}

  @doc false
  def resource() do
    {
      "Invoice",
      &resource_maker/1
    }
  end

  @doc false
  def resource_maker(json) do
    %Invoice{
      amount: json[:amount],
      due: json[:due] |> Check.date_or_datetime(),
      tax_id: json[:tax_id],
      name: json[:name],
      expiration: json[:expiration],
      fine: json[:fine],
      interest: json[:interest],
      discounts: json[:discounts] |> Enum.map(fn discount -> %{discount | "due" => discount["due"] |> Check.date_or_datetime()} end),
      tags: json[:tags],
      descriptions: json[:descriptions],
      pdf: json[:pdf],
      link: json[:link],
      nominal_amount: json[:nominal_amount],
      fine_amount: json[:fine_amount],
      interest_amount: json[:interest_amount],
      discount_amount: json[:discount_amount],
      id: json[:id],
      brcode: json[:brcode],
      status: json[:status],
      fee: json[:fee],
      transaction_ids: json[:transaction_ids],
      created: json[:created] |> Check.datetime(),
      updated: json[:updated] |> Check.datetime()
    }
  end
end

defmodule StarkBank.Webhook do
  alias __MODULE__, as: Webhook

  @enforce_keys [:url, :subscriptions]
  defstruct [:id, :url, :subscriptions]

  @type t() :: %__MODULE__{}

  @doc false
  def resource() do
    {
      "Webhook",
      &resource_maker/1
    }
  end

  @doc false
  def resource_maker(json) do
    %Webhook{
      id: json[:id],
      url: json[:url],
      subscriptions: json[:subscriptions]
    }
  end
end

defmodule StarkBank.Boleto do
  alias __MODULE__, as: Boleto
  alias StarkCore.Utils.Check

  @enforce_keys [
    :amount,
    :name,
    :tax_id,
    :street_line_1,
    :street_line_2,
    :district,
    :city,
    :state_code,
    :zip_code
  ]
  defstruct [
    :amount,
    :name,
    :tax_id,
    :street_line_1,
    :street_line_2,
    :district,
    :city,
    :state_code,
    :zip_code,
    :due,
    :fine,
    :interest,
    :overdue_limit,
    :receiver_name,
    :receiver_tax_id,
    :tags,
    :descriptions,
    :discounts,
    :id,
    :fee,
    :line,
    :bar_code,
    :transaction_ids,
    :status,
    :created,
    :our_number
  ]

  @type t() :: %__MODULE__{}

  @doc false
  def resource() do
    {
      "Boleto",
      &resource_maker/1
    }
  end

  @doc false
  def resource_maker(json) do
    %Boleto{
      amount: json[:amount],
      name: json[:name],
      tax_id: json[:tax_id],
      street_line_1: json[:street_line_1],
      street_line_2: json[:street_line_2],
      district: json[:district],
      city: json[:city],
      state_code: json[:state_code],
      zip_code: json[:zip_code],
      due: json[:due] |> Check.datetime(),
      fine: json[:fine],
      interest: json[:interest],
      overdue_limit: json[:overdue_limit],
      receiver_name: json[:receiver_name],
      receiver_tax_id: json[:receiver_tax_id],
      tags: json[:tags],
      descriptions: json[:descriptions],
      discounts: json[:discounts] |> Enum.map(fn discount -> %{discount | "date" => discount["date"] |> Check.datetime()} end),
      id: json[:id],
      fee: json[:fee],
      line: json[:line],
      bar_code: json[:bar_code],
      transaction_ids: json[:transaction_ids],
      status: json[:status],
      created: json[:created] |> Check.datetime(),
      our_number: json[:our_number]
    }
  end
end

defmodule StarkBank.Invoice.Payment do
  alias StarkBank.Invoice

  @moduledoc """
  Groups Invoice.Payment related functions
  """

  @doc """
  When an Invoice is paid, its Payment sub-resource will become available.
  It carries all the available information about the invoice payment.

  ## Attributes:
    - `:amount` [integer]: amount in cents that was paid. ex: 1234 (= R$ 12.34)
    - `:name` [string]: payer full name. ex: "Anthony Edward Stark"
    - `:tax_id` [string]: payer tax ID (CPF or CNPJ). ex: "20.018.183/0001-80"
    - `:bank_code` [string]: code of the payer bank institution in Brazil. ex: "20018183"
    - `:branch_code` [string]: payer bank account branch. ex: "1357-9"
    - `:account_number` [string]: payer bank account number. ex: "876543-2"
    - `:account_type` [string]: payer bank account type. ex: "checking", "savings", "salary" or "payment"
    - `:end_to_end_id` [string]: central bank's unique transaction ID. ex: "E79457883202101262140HHX553UPqeq"
    - `:method` [string]: payment method that was used. ex: "pix"
  """
  defstruct [
    :name,
    :tax_id,
    :bank_code,
    :branch_code,
    :account_number,
    :account_type,
    :amount,
    :end_to_end_id,
    :method
  ]

  @type t() :: %__MODULE__{}

  def resource() do
    {
      "Payment",
      &resource_maker/1
    }
  end

  def resource_maker(json) do
    %Invoice.Payment{
      name: json[:name],
      tax_id: json[:tax_id],
      bank_code: json[:bank_code],
      branch_code: json[:branch_code],
      account_number: json[:account_number],
      account_type: json[:account_type],
      amount: json[:amount],
      end_to_end_id: json[:end_to_end_id],
      method: json[:method]
    }
  end
end

defmodule StarkCoreTestRest.GetRaw do
  alias StarkCore.Utils.Rest
  use ExUnit.Case

  @tag :get_raw
  test "Should get balance using get_raw" do
    {:ok, response} = Rest.get_raw(:bank, "balance", %{})
    balance = List.first(response["balances"])
    assert !is_nil(balance["amount"])
  end

  @tag :get_raw
  test "Should get balance using get_raw!" do
    response = Rest.get_raw!(:bank, "balance", %{})
    balance = List.first(response["balances"])
    assert !is_nil(balance["amount"])
  end

  @tag :get_raw_fail
  test "Should silently fail to get balance using get_raw" do
    assert {:error, _response} = Rest.get_raw(:bank, "balancex", %{})
  end

  @tag :get_raw_fail
  test "Should raise error to get balance using get_raw!" do
    assert_raise(RuntimeError, fn ->
      Rest.get_raw!(:bank, "balancex", %{})
    end)
  end
end

defmodule StarkCoreTestRest.PostRaw do
  alias StarkCore.Utils.Rest
  use ExUnit.Case

  @tag :post_raw
  test "Should create invoices using Rest.post_raw" do
    {:ok, invoices_created} = Rest.post_raw(
      :bank,
      "invoice",
      %{
        payload: %{
          invoices: [
            %{
              amount: 15000,
              taxId: "45.059.493/0001-73",
              name: "Should create a new Invoice using Rest.post_raw"
            }
          ]
        }
      }
    )
    invoice_created = List.first(invoices_created["invoices"])
    assert invoice_created["amount"] > 0
  end

  @tag :post_raw
  test "Should create invoices using Rest.post_raw!" do
    invoices_created = Rest.post_raw!(
      :bank,
      "invoice",
      %{
        payload: %{
          invoices: [
            %{
              amount: 15000,
              taxId: "45.059.493/0001-73",
              name: "Should create a new Invoice using Rest.post_raw"
            }
          ]
        }
      }
    )
    invoice_created = List.first(invoices_created["invoices"])
    assert invoice_created["amount"] > 0
  end

  @tag :post_raw_fail
  test "Should silently fail to create invoices using Rest.post_raw" do
    assert {:error, _} = Rest.post_raw(
      :bank,
      "invoice",
      %{
        payload: %{
          invoices: [
            %{
              amount: 15000,
              taxId: "12344",
              name: "Should fail to create a new Invoice using Rest.post_raw"
            }
          ]
        }
      }
    )
  end

  @tag :post_raw_fail
  test "Should raise error to create invoices using Rest.post_raw!" do
    assert_raise RuntimeError, fn ->
      Rest.post_raw!(
        :bank,
        "invoice",
        %{
          payload: %{
            invoices: [
              %{
                amount: 15000,
                taxId: "1234",
                name: "Should fail to create a new Invoice using Rest.post_raw"
              }
            ]
          }
        }
      )
    end
  end
end

defmodule StarkCoreTestRest.GetPage do
  alias StarkCore.Utils.Rest
  alias StarkBank.Balance
  use ExUnit.Case

  @tag :get_page
  test "Should get balance using get_page" do
    {:ok, {_, response}} = Rest.get_page(
      :bank,
      Balance.resource(),
      %{}
    )
    balance = List.first(response)
    assert !is_nil(balance.amount)
  end

  @tag :get_page
  test "Should fail silently using get_page on non existent resource" do
    assert {:error, _} = Rest.get_page(
      :bank,
      Balance.non_existent_resource(),
      %{}
    )
  end

  @tag :get_page
  test "Should fail and raise error using get_page! on non existent resource" do
    assert_raise RuntimeError, fn ->
      Rest.get_page!(
        :bank,
        Balance.non_existent_resource(),
        %{}
      )
    end
  end
end

defmodule StarkCoreTestRest.GetList do
  alias StarkCore.Utils.Rest
  alias StarkBank.Balance
  alias StarkBank.Invoice
  use ExUnit.Case

  @tag :get_list
  test "Should get a list of invoices using get_list" do
    [ok: invoice] = Rest.get_list(
      :bank,
      Invoice.resource(),
      %{limit: 3}
    )
      |> Enum.take(1)

    assert invoice.amount
  end

  @tag :get_list
  test "Should silently fail to get a list of invoices using get_list" do
    assert [error: _invoice] = Rest.get_list(
      :bank,
      Balance.non_existent_resource(),
      %{
        limit: 3
      })
        |> Enum.take(1)
  end

  @tag :get_list
  test "Should get a list of invoices using get_list!" do
    [invoice] = Rest.get_list!(
      :bank,
      Invoice.resource(),
      %{limit: 3})
      |> Enum.take(1)

    assert invoice.amount
  end

  @tag :get_list
  test "Should fail and raise error using get_list!" do
    assert_raise RuntimeError, fn ->
      Rest.get_list!(
        :bank,
        Balance.non_existent_resource(),
        %{limit: 3}
      )
        |> Enum.take(1)
    end
  end
end

defmodule StarkCoreTestRest.GetId do
  alias StarkCore.Utils.Rest
  alias StarkBank.Invoice
  use ExUnit.Case

  @tag :get_id
  test "Should get an invoice by id using get_id" do
    [ok: invoice_listed] = Rest.get_list(
      :bank,
      Invoice.resource(),
      %{limit: 3})
      |> Enum.take(1)

    {:ok, invoice} = Rest.get_id(
      :bank,
      Invoice.resource(),
      invoice_listed.id,
      %{})

    assert !is_nil(invoice.amount)
  end

  @tag :get_id
  test "Should get an invoice by id using get_id!" do
    [invoice_listed] = Rest.get_list!(
      :bank,
      Invoice.resource(),
      %{limit: 3})
      |> Enum.take(1)

    invoice = Rest.get_id!(
      :bank,
      Invoice.resource(),
      invoice_listed.id,
      %{})

    assert !is_nil(invoice.amount)
  end

  @tag :get_id
  test "Should silently fail using get_id on non existant id" do
    assert {:error, _} = Rest.get_id(
      :bank,
      Invoice.resource(),
      "123412341234",
      %{})
  end

  @tag :get_id
  test "Should raise error using get_id! on non existant id" do
    assert_raise RuntimeError, fn ->
      Rest.get_id!(
        :bank,
        Invoice.resource(),
        "123412341234",
        %{}
      )
    end
  end
end

defmodule StarkCoreTestRest.GetContent do
  alias StarkCore.Utils.Rest
  alias StarkBank.Invoice
  use ExUnit.Case


  @tag :get_content
  test "Should get qrcode of invoice using get_content" do
    [invoice_listed] = Rest.get_list!(
      :bank,
      Invoice.resource(),
      %{limit: 3}
    )
      |> Enum.take(1)

    assert {:ok, _response} = Rest.get_content(
      :bank,
      Invoice.resource(),
      invoice_listed.id,
      "pdf",
      %{}
    )
  end

  @tag :get_content
  test "Should get qrcode of invoice using get_content!" do
    [invoice_listed] = Rest.get_list!(
      :bank,
      Invoice.resource(),
      %{limit: 3}
    )
      |> Enum.take(1)

    response = Rest.get_content!(
      :bank,
      Invoice.resource(),
      invoice_listed.id,
      "pdf",
      %{}
    )

    assert length(response) > 0
  end

  @tag :get_content
  test "Should silently fail to get qrcode of invoice using get_content on non existant Invoice ID" do
    assert {:error, _response} = Rest.get_content(
      :bank,
      Invoice.resource(),
      "123412341234",
      "pdf",
      %{}
    )
  end

  @tag :get_content
  test "Should raise error to get qrcode of invoice using get_content on non existant Invoice ID" do
    assert_raise RuntimeError, fn ->
      Rest.get_content!(
        :bank,
        Invoice.resource(),
        "123412341234",
        "pdf",
        %{}
      )
    end
  end
end

defmodule StarkCoreTestRest.Post do
  alias StarkCore.Utils.Rest
  alias StarkBank.Invoice
  use ExUnit.Case

  @tag :post
  test "Should create a new Invoice using post" do

    assert {:ok, _} = Rest.post(
      :bank,
      Invoice.resource(),
      %{
        payload: %{
          invoices: [
            %{
              amount: 15000,
              taxId: "45.059.493/0001-73",
              name: "Should create a new Invoice using Rest.post"
            }
          ]
        }
      }
    )
  end

  @tag :post
  test "Should create a new Invoice using post!" do
    invoices_created = Rest.post!(
      :bank,
      Invoice.resource(),
      %{
        payload: %{
          invoices: [%{
            amount: 15000,
            taxId: "45.059.493/0001-73",
            name: "Should create a new Invoice using Rest.post"
          }]
        }
      }
    )
    invoice_created = List.first(invoices_created)
    assert invoice_created.amount > 0
  end

  @tag :post
  test "Should silently fail to create an invoice using post" do
    assert {:error, _} = Rest.post(
      :bank,
      Invoice.resource(),
      %{
        payload: %{
          invoices: [%{
            amount: 15000,
            tax_id: "10293401239420",
            name: "Should create a new Invoice using Rest.post"
          }]
        }
      }
    )
  end

  @tag :post
  test "Should raise error to create an invoice using post!" do
    assert_raise RuntimeError, fn ->
      Rest.post!(
        :bank,
        Invoice.resource(),
        %{
          payload: %{
            invoices: [%{
              amount: 15000,
              taxId: "10293401239420",
              name: "Should create a new Invoice using Rest.post"
            }]
          }
        }
      )
    end
  end
end

defmodule StarkCoreTestRest.PostSingle do
  alias StarkCore.Utils.Rest
  alias StarkBank.Webhook
  use ExUnit.Case

  setup do
    # TBD: Clear only the webhook needed
    webhook_stream = Rest.get_list!(:bank, Webhook.resource(), %{})

    Enum.map(webhook_stream, fn item ->
      IO.inspect(item, label: "item found")

      if item.url == "https://webhook.site/test" do
        deletion_response = Rest.delete_id(
          :bank,
          Webhook.resource(),
          item.id,
          %{}
        )

        case deletion_response do
          {:ok, webhook_deleted} -> {item.id, webhook_deleted.url}
          {:error, [webhook_deleted]} -> {item.id, webhook_deleted.message}
        end
      end
    end)
  end

  @tag :post_single
  test "Should create an Webhook subscription using post_single" do
    assert {:ok, _response} = Rest.post_single(
      :bank,
      Webhook.resource(),
      %{
        payload: %{
          url: "https://webhook.site/test",
          subscriptions: [
            "invoice"
          ]
        }
      }
    )
  end

  @tag :post_single
  test "Should create Webhook subscription using post_single!" do
    assert Rest.post_single!(
      :bank,
      Webhook.resource(),
      %{
        payload: %{
          url: "https://webhook.site/test",
          subscriptions: [
            "invoice"
          ]
        }
      })
  end

  @tag :post_single
  test "Should fail silently trying to create a webhook using post_single" do
    assert {:error, _response} = Rest.post_single(
      :bank,
      Webhook.resource(),
      %{
        payload: %{
          url: "https://site/test",
          subscriptions: [
            "invoice"
          ]
        }
      })
  end

  @tag :post_single
  test "Should raise error trying to create webhook using post_single!" do
    assert_raise RuntimeError, fn ->
      Rest.post_single!(
      :bank,
      Webhook.resource(),
      %{
        payload: %{
          url: "https://site/test",
          subscriptions: [
            "invoice"
          ]
        }
      })
    end
  end
end

defmodule StarkCoreTestRest.DeleteRaw do
  alias StarkCore.Utils.Rest
  alias StarkBank.Boleto
  use ExUnit.Case

  setup do
    {:ok, created_boleto} = Rest.post(
      :bank,
      Boleto.resource(),
      %{
        payload: %{
          boletos: [%{
            amount: 15000,
            taxId: "45.059.493/0001-73",
            name: "Should create a new Invoice using Rest.post",
            streetLine1: "Rua Lagoa Panema, 145",
            streetLine2: "Casa 2",
            district: "Bela Vista",
            city: "São Paulo",
            stateCode: "SP",
            zipCode: "02051-050"
          }]
        }
      }
    )

    {:ok, [boleto: created_boleto |> hd]}
  end

  @tag :delete
  test "Should delete the created Boleto by its ID using delete_raw", state do
    assert {:ok, _deleted_response} = Rest.delete_raw(
      :bank,
      "boleto",
      state[:boleto].id,
      %{}
    )
  end

  @tag :delete
  test "Should delete the created Boleto by its ID using delete_raw!", state do
    assert Rest.delete_raw!(
      :bank,
      "boleto",
      state[:boleto].id,
      %{}
    )
  end

  @tag :delete_fail
  test "Should silently fail trying delete a Boleto using delete_raw with an INVALID_ID" do
    assert {:error, _deleted_response} = Rest.delete_raw(
      :bank,
      "boleto",
      "INVALID_ID",
      %{}
    )
  end

  @tag :delete_fail
  test "Should raise error when trying delete a Boleto using delete_raw! with an INVALID_ID" do
    assert_raise RuntimeError, fn ->
      Rest.delete_raw!(
        :bank,
        "boleto",
        "INVALID_ID",
        %{}
      )
    end
  end
end

defmodule StarkCoreTestRest.Delete do
  alias StarkCore.Utils.Rest
  alias StarkBank.Boleto
  use ExUnit.Case

  setup do
    {:ok, created_boleto} = Rest.post(
      :bank,
      Boleto.resource(),
      %{
        payload: %{
          boletos: [%{
            amount: 15000,
            taxId: "45.059.493/0001-73",
            name: "Should create a new Invoice using Rest.post",
            streetLine1: "Rua Lagoa Panema, 145",
            streetLine2: "Casa 2",
            district: "Bela Vista",
            city: "São Paulo",
            stateCode: "SP",
            zipCode: "02051-050"
          }]
        }
      }
    )

    {:ok, [boleto: created_boleto |> hd]}
  end

  @tag :delete
  test "Should delete the created Boleto by its ID", state do
    assert {:ok, _deleted_response} = Rest.delete_id(
      :bank,
      Boleto.resource(),
      state[:boleto].id,
      %{}
    )
  end

  @tag :delete
  test "Should delete the created Boleto by its ID using delete_id!", state do
    assert Rest.delete_id!(
      :bank,
      Boleto.resource(),
      state[:boleto].id,
      %{}
    )
  end

  @tag :delete_fail
  test "Should silently fail trying delete a Boleto using delete_id with an INVALID_ID" do
    assert {:error, _deleted_response} = Rest.delete_id(
      :bank,
      Boleto.resource(),
      "INVALID_ID",
      %{}
    )
  end

  @tag :delete_fail
  test "Should raise error when trying delete a Boleto using delete_id! with an INVALID_ID" do
    assert_raise RuntimeError, fn ->
      Rest.delete_id!(
        :bank,
        Boleto.resource(),
        "INVALID_ID",
        %{}
      )
    end
  end
end

defmodule StarkCoreTestRest.PatchId do
  alias StarkCore.Utils.Rest
  alias StarkBank.Invoice
  use ExUnit.Case

  setup do
    {:ok, created_invoice} = Rest.post(
      :bank,
      Invoice.resource(),
      %{
        payload: %{
          invoices: [%{
            amount: 15000,
            taxId: "45.059.493/0001-73",
            name: "Should create a new Invoice using Rest.post"
          }]
        }
      }
    )

    {:ok, [invoice: created_invoice |> hd]}
  end

  @tag :patch
  test "Should patch Invoice by its ID", state do
    assert {:ok, _response} = Rest.patch_id(
      :bank,
      Invoice.resource(),
      state[:invoice].id,
      %{
        payload: %{
          amount: 20000,
          expiration: 3600
        }
      }
    )
  end

  @tag :patch
  test "Should patch Invoice by its ID using patch_id!", state do
    assert Rest.patch_id(
      :bank,
      Invoice.resource(),
      state[:invoice].id,
      %{
        payload: %{
          amount: 20000,
          expiration: 3600
        }
      }
    )
  end

  @tag :patch_fail
  test "Should silently fail patch Invoice using patch_id with INVALID_ID" do
    assert {:error, _response} = Rest.patch_id(
      :bank,
      Invoice.resource(),
      "INVALID_ID",
      %{
        payload: %{
          amount: 20000,
          expiration: 3600
        }
      }
    )
  end

  @tag :patch_fail
  test "Should raise error trying to patch Invoice using patch_id! with INVALID_ID" do
    assert_raise RuntimeError, fn ->
      Rest.patch_id!(
        :bank,
        Invoice.resource(),
        "INVALID_ID",
        %{
          payload: %{
            amount: 20000,
            expiration: 3600
          }
        }
      )
    end
  end
end

defmodule StarkCoreTestRest.PatchRaw do
  alias StarkCore.Utils.Rest
  alias StarkBank.Invoice
  use ExUnit.Case

  setup do
    {:ok, created_invoice} = Rest.post(
      :bank,
      Invoice.resource(),
      %{
        payload: %{
          invoices: [%{
            amount: 15000,
            taxId: "45.059.493/0001-73",
            name: "Should create a new Invoice using Rest.post"
          }]
        }
      }
    )

    {:ok, [invoice: created_invoice |> hd]}
  end

  @tag :patch_raw
  test "Should patch Invoice by its ID using patch_raw", state do
    assert {:ok, _response} = Rest.patch_raw(
      :bank,
      "invoice",
      state[:invoice].id,
      %{
        payload: %{
          amount: 20000,
          expiration: 3600
        }
      }
    )
  end

  @tag :patch
  test "Should patch Invoice by its ID using patch_raw!", state do
    assert Rest.patch_raw!(
      :bank,
      "invoice",
      state[:invoice].id,
      %{
        payload: %{
          amount: 20000,
          expiration: 3600
        }
      }
    )
  end

  @tag :patch_fail
  test "Should silently fail patch Invoice using patch_raw with INVALID_ID" do
    assert {:error, _response} = Rest.patch_raw(
      :bank,
      "invoice",
      "INVALID_ID",
      %{
        payload: %{
          amount: 20000,
          expiration: 3600
        }
      }
    )
  end

  @tag :patch_fail
  test "Should raise error trying to patch Invoice using patch_raw! with INVALID_ID" do
    assert_raise RuntimeError, fn ->
      Rest.patch_raw!(
        :bank,
        "invoice",
        "INVALID_ID",
        %{
          payload: %{
            amount: 20000,
            expiration: 3600
          }
        }
      )
    end
  end
end

defmodule StarkCoreTestRest.GetSubResource do
  alias StarkCore.Utils.Rest
  alias StarkBank.Invoice
  alias StarkBank.Invoice.Payment
  use ExUnit.Case

  setup do
    [ok: paid_invoice] = Rest.get_list(
      :bank,
      Invoice.resource(),
      %{
        query: %{
          status: "paid",
          limit: 1
        }
      }
    )
      |> Enum.take(1)

    {:ok, [invoice: paid_invoice]}
  end

  @tag :get_sub_resource
  test "Should get Payment sub-resource of paid Invoice using get_sub_resource", state do
    assert {:ok, _} = Rest.get_sub_resource(
      :bank,
      Invoice.resource() |> elem(0),
      Payment.resource(),
      state[:invoice].id,
      %{}
    )
  end

  @tag :get_sub_resource
  test "Should get Payment sub-resource of paid Invoice using get_sub_resource!", state do
    assert Rest.get_sub_resource!(
      :bank,
      Invoice.resource() |> elem(0),
      Payment.resource(),
      state[:invoice].id,
      %{}
    )
  end

  @tag :get_sub_resource_fail
  test "Should silently fail to get Payment sub-resource of Invoice using get_sub_resource with INVALID_ID" do
    assert {:error, _} = Rest.get_sub_resource(
      :bank,
      Invoice.resource() |> elem(0),
      Payment.resource(),
      "INVALID_ID",
      %{}
    )
  end

  @tag :get_sub_resource_fail
  test "Should raise error trying to get Payment sub-resource of Invoice using get_sub_resource! with INVALID_ID" do
    assert_raise RuntimeError, fn ->
      Rest.get_sub_resource!(
        :bank,
        Invoice.resource() |> elem(0),
        Payment.resource(),
        "INVALID_ID",
        %{}
      )
    end
  end
end
