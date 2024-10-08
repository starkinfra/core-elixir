defmodule StarkCore.Utils.QueryGenerator do
  @moduledoc false

  alias StarkCore.Utils.Check
  alias StarkCore.Utils.JSON
  alias StarkCore.Utils.API

  def start_query(function, key, query) do
    Task.start_link(
      fn ->
        yield([], function, key, query, true)
      end
    )
  end

  def get(pid) do
    send(pid, self())

    receive do
      :halt -> :halt
      {:ok, element} -> {:ok, element}
      {:error, errors} -> {:error, errors}
    end
  end

  defp yield([head | tail], function, key, query) do
    receive do
      caller ->
        send(caller, {:ok, head})
        yield(tail, function, key, query)
    end
  end

  defp yield([], function, key, query, first \\ false) do
    limit = query[:limit]
    cursor = query[:cursor]

    if (first or (!is_nil(cursor) and cursor != "")) and (is_nil(limit) or limit > 0) do
      case function.(query |> Map.put(:limit, limit |> Check.limit()) |> API.cast_json_to_api_format()) do
        {:ok, result} ->
          decoded = JSON.decode!(result)
          result_quantity = length(result)

          yield(
            decoded[key],
            function,
            key,
            query
              |> Map.put(:cursor, decoded["cursor"])
              |> Map.put(:limit, iterate_limit(limit, result_quantity))
          )

        {:error, error} ->
          yield_error(error)
      end
    else
      receive do
        caller ->
          send(caller, :halt)
      end
    end
  end

  defp yield_error(error) do
    receive do
      caller ->
        send(caller, {:error, error})
    end

    receive do
      caller ->
        send(caller, :halt)
    end
  end

  defp iterate_limit(limit, _result_quantity) when is_nil(limit) do
    nil
  end

  defp iterate_limit(limit, result_quantity) do
    limit - result_quantity
  end
end
