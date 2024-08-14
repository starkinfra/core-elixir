defmodule StarkCore.Utils.Check do
  @moduledoc false

  alias EllipticCurve.PrivateKey
  alias StarkCore.User.Project
  alias StarkCore.User.Organization

  def environment(environment) do
    case environment do
      :production -> environment
      :sandbox -> environment
      nil -> raise "please set an environment"
      _any -> raise "environment must be either :production or :sandbox"
    end
  end

  def limit(limit) when is_nil(limit) do
    nil
  end

  def limit(limit) do
    min(limit, 100)
  end

  def datetime(data) when is_nil(data) do
    nil
  end

  def datetime(data) when is_binary(data) do
    {:ok, datetime, _utc_offset} = data |> DateTime.from_iso8601()
    datetime
  end

  def date(data) when is_nil(data) do
    nil
  end

  def date(data) when is_binary(data) do
    data |> Date.from_iso8601!()
  end

  def date(data = %DateTime{}) do
    %Date{year: data.year, month: data.month, day: data.day}
  end

  def date(data) do
    data
  end

  def date_or_datetime(data) do
    try do
      date(data)
    rescue
      ArgumentError -> datetime(data)
    end
  end

  def private_key(private_key) do
    try do
      {:ok, parsed_key} = PrivateKey.fromPem(private_key)
      :secp256k1 = parsed_key.curve.name
      parsed_key
    rescue
      _e -> raise "private_key must be valid secp256k1 ECDSA string in pem format"
    else
      parsed_key -> parsed_key
    end
  end

  def query_params(query) do
    query
    |> fill_limit()
    |> fill_date_field(:after)
    |> fill_date_field(:before)
  end

  defp fill_limit(options) do
    if !options[:limit] do
      Keyword.put(options, :limit, nil)
    end
    options
  end

  defp fill_date_field(options, field) do
    if !options[field] do
      Keyword.put(options, field, nil)
    else
      Keyword.update!(options, field, &date/1)
    end
  end

  def user(user) when is_nil(user) do
    case Application.fetch_env(:starkcore, :project) do
      {:ok, project_info} -> {:ok, project_info
        |> StarkCore.project()}
      :error -> organization_user()
    end
  end

  def user(user = %Project{}) do
    {:ok, user}
  end

  def user(user = %Organization{}) do
    {:ok, user}
  end

  defp organization_user() do
    case Application.fetch_env(:starkcore, :organization) do
      {:ok, organization_info} -> organization_info |> StarkCore.organization()
      :error -> raise "no default user was located in configs and no user was passed in the request"
    end
  end


  def host(input) do
    case Enum.member?([:bank, :infra, :sign], input) do
      true -> {:ok, input}
      false -> {:error, "service #{input} is invalid"}
    end
  end

  def language(lang) when is_binary(lang) do
    case Enum.member?(["en-US", "pt-BR"], lang) do
      true -> String.to_charlist(lang)
      false -> ~c"en-US"
    end
  end

  def language(lang) when is_nil(lang) do
    case Application.fetch_env(:starkcore, :language) do
      {:ok, ~c"en-US"} -> ~c"en-US"
      {:ok, "en-US"} -> ~c"en-US"
      {:ok, ~c"pt-BR"} -> ~c"pt-BR"
      {:ok, "pt-BR"} -> ~c"pt-BR"
      :error -> ~c"en-US"
    end
  end

  def enforced_keys(parameters, enforced_keys) do
    case get_missing_keys(parameters |> Enum.into(%{}), enforced_keys) do
      [] -> parameters
      missing_keys -> raise "the following parameters are missing: " <> Enum.join(missing_keys, ", ")
    end
  end

  def get_missing_keys(parameters, [key | other_enforced_keys]) do
    missing_keys = get_missing_keys(parameters, other_enforced_keys)
    case Map.has_key?(parameters, key) do
      true -> missing_keys
      false -> [key | missing_keys]
    end
  end

  def get_missing_keys(_parameters, []) do
    # TBD: Implementation
    []
  end
end
