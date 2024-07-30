defmodule StarkCore.Utils.Request do
  @moduledoc false

  alias StarkCore.Utils.JSON
  alias StarkCore.Utils.Check
  alias StarkCore.Utils.URL
  alias StarkCore.Project
  alias StarkCore.Organization
  alias StarkCore.Error

  @type options :: [
    payload: map(),
    query: list(),
    user: Project.t() | Organization.t()
  ]

  @spec fetch(
    String.t(),
    atom(),
    String.t(),
    %{
      payload: map(),
      query: list(),
      user: Project.t() | Organization.t(),
      sdk_version: String.t(),
      api_version: String.t(),
      language: String.t(),
      timeout: number(),
      prefix: String.t()
    }
  ) :: {:ok, String.t()} | {:error, [Error.t()]}
  def fetch(
    host,
    method,
    path,
    opts
  ) do
    with {:ok, _} <- Check.host(host),
      {:ok, user} <- Check.user(Map.get(opts, :user)) do
      request(
        user,
        method,
        URL.get_url(host, user.environment, opts.api_version, path, opts.query),
        opts.payload,
        opts.prefix,
        opts.sdk_version,
        opts.language,
        opts.timeout
      )
        |> process_response
    else
      {:error, message} -> {:error, message}
    end
  end

  defp request(
    user,
    method,
    url,
    payload,
    prefix,
    sdk_version,
    language,
    timeout_seconds
  ) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    http_request_opts = [
      timeout: timeout_seconds * 1000,
      ssl: [
        cacerts: :public_key.cacerts_get()
      ],
    ]

    req_params = get_request_params(user, url, payload, prefix, sdk_version, language)

    {:ok, {{~c"HTTP/1.1", status_code, _message}, _headers, response_body}} = :httpc.request(
      method,
      req_params,
      http_request_opts,
      []
    )
    {status_code, response_body}
  end

  defp get_request_params(user, url, body, prefix, sdk_version, language) when is_nil(body) do
    {
      String.to_charlist(URI.encode(url)),
      get_headers(user, "", prefix, sdk_version, language)
    }
  end

  defp get_request_params(user, url, body, prefix, sdk_version, language) do
      {
        String.to_charlist(url),
        get_headers(user, body, prefix, sdk_version, language),
        ~c"text/plain",
        JSON.encode!(body)
      }
  end

  defp get_headers(user, body, prefix, sdk_version, language) when is_map(body) do
    body_string = JSON.encode!(body)

    get_headers(user, body_string, prefix, sdk_version, language)
  end

  defp get_headers(user, body, prefix, sdk_version, language) when is_binary(body) do
    access_time = DateTime.utc_now() |> DateTime.to_unix(:second)

    signature =
      "#{user.access_id}:#{access_time}:#{body}"
      |> EllipticCurve.Ecdsa.sign(user.private_key)
      |> EllipticCurve.Signature.toBase64()

    prefix_final = case String.length(prefix) > 0 do
      true -> ~c"#{prefix}-Elixir-#{System.version()}-SDK-#{sdk_version}"
      false -> ~c"Elixir-#{System.version()}-SDK-#{sdk_version}"
    end

    [
      {~c"Access-Id", to_charlist(user.access_id)},
      {~c"Access-Time", Integer.to_charlist(access_time)},
      {~c"Access-Signature", to_charlist(signature)},
      {~c"Content-Type", ~c"application/json"},
      {~c"User-Agent", prefix_final},
      {~c"Accept-Language", Check.language(language)}
    ]
  end

  defp process_response({status_code, body}) do
    case status_code do
      500 -> {:error, [%Error{code: "internalServerError", message: "Houston, we have a problem."}]}
      400 -> {:error,
        JSON.decode!(body)["errors"]
          |> Enum.map(fn error -> %Error{code: error["code"], message: error["message"]} end)}
      200 -> {:ok, body}
      _ -> {:error,
        [%Error{
          code: "unknownError",
          message: "Unknown exception encountered: " <> to_string(body)}
        ]
      }
    end
  end
end
