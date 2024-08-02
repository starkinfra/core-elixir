defmodule StarkCore.Project do
  alias __MODULE__, as: Project
  alias StarkCore.User

  @moduledoc false
  @type t :: %Project{environment: :production | :sandbox, id: String.t(), access_id: String.t(), private_key: String.t()}
  defstruct [:environment, :id, :access_id, :private_key]

  def validate(environment, id, private_key) do
    {environment, private_key} = User.validate(private_key, environment)

    %Project{
      environment: environment,
      id: id,
      access_id: accessId(id),
      private_key: private_key,
    }
  end

  def accessId(id) do
    "project/#{id}"
  end
end
