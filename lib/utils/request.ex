defmodule StarkCore.Utils.Request do
  @moduledoc false

  alias StarkCore.Utils.JSON
  alias StarkCore.Utils.Check
  alias StarkCore.Utils.URL
  alias StarkCore.Project
  alias StarkCore.Organization
  alias StarkCore.Error

  @spec fetch(atom(), String.t(), [payload: map(), query: list(), version: String.t(), user: Project.t() | Organization.t()]) :: {:ok, String.t()} | {:error, [Error.t()]}
  def fetch(method, path, options \\ []) do
    %{payload: payload, query: query, version: version, user: user_parameter} =
      Enum.into(options, %{payload: nil, query: nil, version: "v2", user: nil})

    user = user_parameter |> Check.user()

    request(
      user,
      method,
      URL.get_url(user.environment, version, path, query),
      payload
    ) |> process_response
  end

  defp request(user, method, url, payload) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    http_request_opts = [
      ssl: [
        cacerts: :public_key.cacerts_get()
      ]
    ]

    req_params = get_request_params(user, url, payload)

    {:ok, {{~c"HTTP/1.1", status_code, _message}, _headers, response_body}} = :httpc.request(
      method,
      req_params,
      http_request_opts,
      []
    )
    {status_code, response_body}
  end

  defp get_request_params(user, url, body) when is_nil(body) do
    {
      URI.encode(url),
      get_headers(user, "")
    }
  end

  defp get_request_params(user, url, body) do
      {
        url,
        get_headers(user, body),
        ~c"text/plain",
        JSON.encode!(body)
      }
  end

  defp get_headers(user, body) when is_map(body) do
    body_string = JSON.encode!(body)

    get_headers(user, body_string)
  end

  defp get_headers(user, body) when is_binary(body) do
    access_time = DateTime.utc_now() |> DateTime.to_unix(:second)

    signature =
      "#{user.access_id}:#{access_time}:#{body}"
      |> EllipticCurve.Ecdsa.sign(user.private_key)
      |> EllipticCurve.Signature.toBase64()

    [
      {~c"Access-Id", to_charlist(user.access_id)},
      {~c"Access-Time", Integer.to_charlist(access_time)},
      {~c"Access-Signature", to_charlist(signature)},
      {~c"Content-Type", ~c"application/json"},
      {~c"User-Agent", ~c"Elixir-#{System.version()}-SDK-1.0.0"},
      {~c"Accept-Language", Check.language()}
    ]
  end

  defp process_response({status_code, body}) do
    case status_code do
      500 -> {:error, [%Error{code: "internalServerError", message: "Houston, we have a problem."}]}
      400 -> {:error, JSON.decode!(body)["errors"] |> Enum.map(fn error -> %Error{code: error["code"], message: error["message"]} end)}
      200 -> {:ok, body}
      _ -> {:error, [%Error{code: "unknownError", message: "Unknown exception encountered: " <> to_string(body)}]}
    end
  end
end
