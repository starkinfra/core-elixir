defmodule StarkCore.User do
  @moduledoc false

  alias StarkCore.Utils.Check

  def validate(private_key, environment) do
    {
      Check.environment(environment),
      Check.private_key(private_key)
    }
  end
end
