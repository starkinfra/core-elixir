defmodule StarkCore.Utils.Rest do
  alias StarkCore.Utils.Request
  alias StarkCore.Utils.Check
  alias StarkCore.Utils.QueryGenerator
  alias StarkCore.Utils.API
  alias StarkCore.Utils.JSON

  def getDefaultOptions() do
    %{
      payload: nil,
      query: nil,
      user: nil,
      sdk_version: nil,
      api_version: "v2",
      language: "en-US",
      timeout: 15,
      prefix: "",
      limit: 100
    }
  end

  def getJokerDefaultOptions() do
    %{
      payload: nil,
      query: nil,
      user: nil,
      sdk_version: Mix.Project.config()[:version],
      api_version: "v2",
      language: "en-US",
      timeout: 15,
      prefix: "Joker",
      limit: 100
    }
  end

  def get_raw(
    service,
    path,
    options
  ) do
    opts = Map.merge(getJokerDefaultOptions(), options)
    case Request.fetch(
      service,
      :get,
      path,
      opts
    ) do
      {:ok, response} -> {:ok, JSON.decode!(response)}
      {:error, errors} -> {:error, errors}
    end
  end

  def get_raw!(
    service,
    path,
    options
  ) do
    case get_raw(
      service,
      path,
      options
    ) do
      {:ok, response} -> response
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def post_raw(
    service,
    path,
    options
  ) do
    opts = Map.merge(getJokerDefaultOptions(), options)

    case Request.fetch(
      service,
      :post,
      path,
      opts
    ) do
      {:ok, response} -> {:ok, JSON.decode!(response)}
      {:error, errors} -> {:error, errors}
    end
  end

  def post_raw!(
    service,
    path,
    options
  ) do
    case post_raw(
      service,
      path,
      options
    ) do
      {:ok, response} -> response
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def get_page(
    service,
    {resource_name, resource_maker},
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    case Request.fetch(
      service,
      :get,
      "#{API.endpoint(resource_name)}",
      opts
    ) do
      {:ok, response} -> {:ok, process_page_response(resource_name, resource_maker, response)}
      {:error, errors} -> {:error, errors}
    end
  end

  def get_page!(
    service,
    {resource_name, resource_maker},
    options
  ) do
    case get_page(
      service,
      {resource_name, resource_maker},
      options
    ) do
      {:ok, response} -> response
      {:error, err} -> raise API.errors_to_string(err)
    end
  end

  def get_list(
    service,
    {resource_name, resource_maker},
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    {getter, query} = get_list_parameters(service, resource_name, opts)

    Stream.resource(
      fn ->
        {:ok, pid} =
          QueryGenerator.start_query(
            getter,
            API.last_name_plural(resource_name),
            query
          )
        pid
      end,
      fn pid ->
        case QueryGenerator.get(pid) do
          :halt -> {:halt, pid}
          {:ok, element} -> {[{:ok, API.from_api_json(element, resource_maker)}], pid}
          {:error, error} -> {[{:error, error}], pid}
        end
      end,
      fn _pid -> nil end
    )
  end

  def get_list!(
    service,
    {resource_name, resource_maker},
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    {getter, query} = get_list_parameters(service, resource_name, opts)

    Stream.resource(
      fn ->
        {:ok, pid} =
          QueryGenerator.start_query(
            getter,
            API.last_name_plural(resource_name),
            query
          )
        pid
      end,
      fn pid ->
        case QueryGenerator.get(pid) do
          :halt -> {:halt, pid}
          {:ok, element} -> {[API.from_api_json(element, resource_maker)], pid}
          {:error, errors} -> raise API.errors_to_string(errors)
        end
      end,
      fn _pid -> nil end
    )
  end

  defp get_list_parameters(
    service,
    resource_name,
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    query = opts |> Check.query_params()
    {
      make_getter(
        service,
        query[:user],
        resource_name,
        opts
      ),
      query
    }
  end

  defp make_getter(
    service,
    user,
    resource_name,
    opts
  ) do
    fn query ->
      Request.fetch(
        service,
        :get,
        API.endpoint(resource_name),
        opts
      )
    end
  end

  def get_id(
    service,
    {resource_name, resource_maker},
    id,
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)

    case Request.fetch(
      service,
      :get,
      "#{API.endpoint(resource_name)}/#{id}",
      opts
    ) do
      {:ok, response} -> {:ok, process_single_response(response, resource_name, resource_maker)}
      {:error, errors} -> {:error, errors}
    end
  end

  def get_id!(
    service,
    {resource_name, resource_maker},
    id,
    options
  ) do
    case get_id(
      service,
      {resource_name, resource_maker},
      id,
      options
    ) do
      {:ok, entity} -> entity
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def get_content(
    service,
    {resource_name, resource_maker},
    id,
    sub_resource_name,
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    case Request.fetch(
      service,
      :get,
      "#{API.endpoint(resource_name)}/#{id}/#{sub_resource_name}",
      opts
    ) do
      {:ok, content} -> {:ok, content}
      {:error, errors} -> {:error, errors}
    end
  end

  def get_content!(
    service,
    {resource_name, resource_maker},
    id,
    sub_resource_name,
    options
  ) do
    case get_content(
      service,
      {resource_name, resource_maker},
      id,
      sub_resource_name,
      options
    ) do
      {:ok, content} -> content
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def post(
    service,
    {resource_name, resource_maker},
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    case Request.fetch(
      service,
      :post,
      "#{API.endpoint(resource_name)}",
      opts
    ) do
      {:ok, response} -> {:ok, process_response(resource_name, resource_maker, response)}
      {:error, errors} -> {:error, errors}
    end
  end

  def post!(
    service,
    {resource_name, resource_maker},
    options
  ) do
    case post(
      service,
      {resource_name, resource_maker},
      options
    ) do
      {:ok, entities} -> entities
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def post_single(
    service,
    {resource_name, resource_maker},
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    case Request.fetch(
      service,
      :post,
      "#{API.endpoint(resource_name)}",
      opts
    ) do
      {:ok, response} -> {:ok, process_single_response(response, resource_name, resource_maker)}
      {:error, errors} -> {:error, errors}
    end
  end

  def post_single!(
    service,
    {resource_name, resource_maker},
    options
  ) do
    case post_single(
      service,
      {resource_name, resource_maker},
      options
    ) do
      {:ok, entity} -> entity
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def delete_id(
    service,
    {resource_name, resource_maker},
    id,
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    case Request.fetch(
      service,
      :delete,
      "#{API.endpoint(resource_name)}/#{id}",
      opts
    ) do
      {:ok, response} -> {:ok, process_single_response(response, resource_name, resource_maker)}
      {:error, errors} -> {:error, errors}
    end
  end

  def delete_id!(
    service,
    {resource_name, resource_maker},
    id,
    options
  ) do
    case delete_id(
      service,
      {resource_name, resource_maker},
      id,
      options
    ) do
      {:ok, entity} -> entity
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def patch_id(
    service,
    {resource_name, resource_maker},
    id,
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    case Request.fetch(
      service,
      :patch,
      "#{API.endpoint(resource_name)}/#{id}",
      opts
    ) do
      {:ok, response} -> {:ok, process_single_response(response, resource_name, resource_maker)}
      {:error, errors} -> {:error, errors}
    end
  end

  def patch_id!(
    service,
    {resource_name, resource_maker},
    id,
    payload
  ) do
    case patch_id(
      service,
      {resource_name, resource_maker},
      id,
      payload
    ) do
      {:ok, entity} -> entity
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  def get_sub_resource(
    service,
    resource_name,
    {sub_resource_name, sub_resource_maker},
    id,
    options
  ) do
    opts = Map.merge(getDefaultOptions(), options)
    case Request.fetch(
      service,
      :get,
      "#{API.endpoint(resource_name)}/#{id}/#{API.endpoint(sub_resource_name)}",
      opts
    ) do
      {:ok, response} -> {:ok, process_single_response(response, sub_resource_name, sub_resource_maker)}
      {:error, errors} -> {:error, errors}
    end
  end

  def get_sub_resource!(
    service,
    resource_name,
    {sub_resource_name, sub_resource_maker},
    id,
    options
  ) do
    case get_sub_resource(
      service,
      resource_name,
      {sub_resource_name, sub_resource_maker},
      id,
      options
    ) do
      {:ok, entity} -> entity
      {:error, errors} -> raise API.errors_to_string(errors)
    end
  end

  defp process_single_response(
    response,
    resource_name,
    resource_maker
  ) do
    JSON.decode!(response)[API.last_name(resource_name)]
    |> API.from_api_json(resource_maker)
  end

  defp process_response(
    resource_name,
    resource_maker,
    response
  ) do
    JSON.decode!(response)[API.last_name_plural(resource_name)]
    |> Enum.map(fn json -> API.from_api_json(json, resource_maker) end)
  end

  defp process_page_response(
    resource_name,
    resource_maker,
    response
  ) do
    decoded_response = JSON.decode!(response)
    {
      decoded_response["cursor"],
      decoded_response[API.last_name_plural(resource_name)]
        |> Enum.map(&(API.from_api_json(&1, resource_maker)))
    }
  end
end
