defmodule StarkCore.Utils.URL do
  @moduledoc false

  alias StarkCore.Utils.API, as: API

  def get_url(service, environment, version, path, query) do
    (~s'#{base_url(service, environment)}#{version}/#{path}')
    |> add_query(query)
  end

  defp base_url(service, environment) do
    services = [
      infra: "starkinfra",
      bank: "starkbank",
      sign: "starksign"
    ]

    case environment do
      :production -> "https://api.#{services[service]}.com/"
      :sandbox -> "https://sandbox.api.#{services[service]}.com/"
    end
  end

  defp add_query(endpoint, query) when is_nil(query) do
    endpoint
  end

  defp add_query(endpoint, query) do
    list =
      for {k, v} <- query |> API.cast_json_to_api_format(),
          !is_nil(v),
          do: {k |> query_key, v |> query_argument}
    if length(list) > 0 do
      "#{endpoint}?#{to_charlist(URI.encode_query(list))}"
    else
      endpoint
    end
  end

  defp query_key(key) do
    key
    |> to_string()
  end

  defp query_argument(value) when is_list(value) or is_tuple(value) do
    value
    |> Enum.map(fn v -> to_string(elem(v,1)) end)
    |> Enum.join(",")
  end

  defp query_argument(value) do
    value
  end
end
