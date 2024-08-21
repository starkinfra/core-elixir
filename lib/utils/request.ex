defmodule StarkCore.Utils.Request do
  @moduledoc false

  alias StarkCore.Utils.JSON
  alias StarkCore.Utils.Check
  alias StarkCore.Utils.URL
  alias StarkCore.User.Project
  alias StarkCore.User.Organization
  alias StarkCore.Error

  @type requestOptions :: %{
    payload: map(),
    query: map(),
    user: Project.t() | Organization.t(),
    sdk_version: String.t(),
    api_version: String.t(),
    language: String.t(),
    timeout: number(),
    prefix: String.t(),
    sdk_name: String.t()
  }

  @type rawResponse :: %{
    status_code: non_neg_integer(),
    headers: list({String.t(), String.t()}),
    content: any()
  }


  def fetch(host, method, path, options) do
    %{
      payload: payload,
      query: query,
      version: version,
      user: user_parameter,
      prefix: prefix,
      sdk_version: sdk_version,
      language: language,
      timeout_seconds: timeout_seconds,
      limit: limit,
      sdk_name: sdk_name
    } = Enum.into(
      options,
      %{
        payload: nil,
        query: %{},
        version: ~c"v2",
        user: nil,
        prefix: "",
        sdk_version: Mix.Project.config()[:version],
        language: nil,
        timeout_seconds: 15,
        limit: nil,
        sdk_name: "Core"
      }
    )

    with {:ok, _} <- Check.host(host),
      {:ok, user} <- Check.user(user_parameter)
    do
      request(
        user,
        method,
        URL.get_url(
          host,
          user.environment,
          version,
          path,
          query
            |> Map.put(:limit, limit)
        ),
        payload,
        prefix,
        sdk_version,
        language,
        timeout_seconds,
        sdk_name
      )
        |> process_response
    end
  end


  @spec fetch_raw(
    atom(),
    atom(),
    String.t(),
    requestOptions()
  ) :: {:ok, rawResponse()} | {:error, String.t()}
  def fetch_raw(
    host,
    method,
    path,
    options
  ) do
    %{
      payload: payload,
      query: query,
      version: version,
      user: user_parameter,
      prefix: prefix,
      sdk_version: sdk_version,
      language: language,
      timeout_seconds: timeout_seconds,
      limit: limit,
      sdk_name: sdk_name
    } = Enum.into(
      options,
      %{
        payload: nil,
        query: %{},
        version: ~c"v2",
        user: nil,
        prefix: nil,
        sdk_version: Mix.Project.config()[:version],
        language: nil,
        timeout_seconds: 15,
        limit: nil,
        sdk_name: "core"
      }
    )

    with {:ok, _} <- Check.host(host),
      {:ok, user} <- Check.user(user_parameter)
    do
      request(
        user,
        method,
        URL.get_url(
          host,
          user.environment,
          version,
          path,
          query
            |> Map.put(:limit, limit)
        ),
        payload,
        prefix,
        sdk_version,
        language,
        timeout_seconds,
        sdk_name
      )
        |> process_raw_response
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
    timeout_seconds,
    sdk_name
  ) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    http_request_opts = [
      timeout: timeout_seconds * 1000,
      ssl: [
        cacerts: :public_key.cacerts_get()
      ],
    ]

    {:ok, {{~c"HTTP/1.1", status_code, _message}, headers, response_body}} = :httpc.request(
      method,
      get_request_params(user, url, payload, prefix, sdk_version, language, sdk_name) |> IO.inspect(label: "REQUEST PARAMS"),
      http_request_opts,
      []
    )
    {status_code, response_body, headers}
  end


  defp get_request_params(user, url, body, prefix, sdk_version, language, sdk_name) when is_nil(body) do
    {
      String.to_charlist(URI.encode(url)),
      get_headers(user, "", prefix, sdk_version, language, sdk_name)
    }
  end


  defp get_request_params(user, url, body, prefix, sdk_version, language, sdk_name) do
      {
        String.to_charlist(url),
        get_headers(user, body, prefix, sdk_version, language, sdk_name),
        ~c"text/plain",
        JSON.encode!(body)
      }
  end


  defp get_headers(user, body, prefix, sdk_version, language, sdk_name) when is_map(body) do
    body_string = JSON.encode!(body)

    get_headers(user, body_string, prefix, sdk_version, language, sdk_name)
  end


  defp get_headers(user, body, prefix, sdk_version, language, sdk_name) when is_binary(body) do
    access_time = DateTime.utc_now() |> DateTime.to_unix(:second)

    signature =
      "#{user.access_id}:#{access_time}:#{body}"
      |> EllipticCurve.Ecdsa.sign(user.private_key)
      |> EllipticCurve.Signature.toBase64()

    user_agent = case String.length(prefix || "") > 0 do
      true -> ~c"#{prefix}-Elixir-#{System.version()}-SDK-#{sdk_name}-#{sdk_version}"
      false -> ~c"Elixir-#{System.version()}-SDK-#{sdk_name}-#{sdk_version}"
    end

    [
      {~c"Access-Id", to_charlist(user.access_id)},
      {~c"Access-Time", Integer.to_charlist(access_time)},
      {~c"Access-Signature", to_charlist(signature)},
      {~c"Content-Type", ~c"application/json"},
      {~c"User-Agent", user_agent},
      {~c"Accept-Language", Check.language(language)}
    ]
  end


  defp process_response({status_code, body, _headers}) do
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

  defp process_raw_response({status_code, body, headers}) do
    case status_code do
      500 -> {:error, %{
        headers: headers,
        content: [%Error{code: "internalServerError", message: "Houston, we have a problem."}],
        status_code: status_code
      }}
      400 -> {:error, %{
        headers: headers,
        status_code: status_code,
        content: JSON.decode!(body)["errors"]
          |> Enum.map(fn error ->
              %Error{code: error["code"], message: error["message"]}
            end)
      }}
      200 -> {:ok, %{headers: headers, content: body, status_code: status_code}}
      _ -> {:error,
        [%Error{
          code: "unknownError",
          message: "Unknown exception encountered: " <> to_string(body)}
        ]
      }
    end
  end


end
