defmodule StarkCoreTest.PatchMulti do
  alias StarkCore.Utils.Rest
  alias StarkCore.User.Project
  use ExUnit.Case

  # There is no seam to replace the outgoing HTTP call of the core (it goes straight to :httpc), so, like the other tests of
  # this core, these talk to the sandbox and every case is a rejection by the API. Only the invalidHolder case tells PATCH from
  # POST (the sandbox answers the same item with invalidCard to a POST); the other one proves that the items travel under the
  # plural resource name. Reading a successful response into entities is covered by the SDK tests that assign holders.

  defp resource, do: {"IssuingCard", fn json -> json end}

  defp user do
    Project.validate(:sandbox, System.get_env("SANDBOX_ID"), System.get_env("SANDBOX_PRIVATE_KEY"))
  end

  defp rejected_codes(items) do
    {:error, errors} = Rest.patch_multi(:infra, resource(), payload: items, user: user())
    Enum.map(errors, & &1.code)
  end

  test "an item with a partial holder is rejected as invalidHolder" do
    codes = rejected_codes([%{id: "0000000000000001", holder_name: "Tony Stark"}])

    assert "invalidHolder" in codes
  end

  test "an item with an unknown card is rejected as invalidCard" do
    codes = rejected_codes([%{id: "0000000000000001", tags: ["sdk-test"]}])

    assert "invalidCard" in codes
  end

  test "patch_multi! raises with the API error text" do
    error =
      assert_raise RuntimeError, fn ->
        Rest.patch_multi!(:infra, resource(), payload: [%{id: "0000000000000001", tags: ["sdk-test"]}], user: user())
      end

    assert error.message =~ "invalidCard"
  end
end
