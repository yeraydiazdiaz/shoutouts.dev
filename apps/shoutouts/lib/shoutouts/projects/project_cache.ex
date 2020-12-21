defmodule Shoutouts.ProjectCache do
  @moduledoc """
  A project information cache.

  Requests project information and returns it storing it in a cache.
  """
  use GenServer
  # TODO: can we inject this?
  # alias Shoutouts.GitHubApp

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def fetch(name_with_owner) do
    GenServer.call(__MODULE__, {:fetch, name_with_owner})
  end

  # TODO: fetch/TTL

  # GenServer implementations

  @impl true
  def init(_opts) do
    table = :ets.new(:project_cache, [:named_table, read_concurrency: true])
    {:ok, table}
  end

  @impl true
  def handle_call({:fetch, name_with_owner}, _from, table) do
    result = lookup(:ets.lookup(table, name_with_owner), name_with_owner, table)
    {:reply, result, table}
  end

  defp lookup([{name_with_owner, stored_result}], _, _table) do
    IO.inspect("#{name_with_owner} found in cache")
    {:ok, stored_result}
  end

  defp lookup([], name_with_owner, _table) do
    IO.inspect("#{name_with_owner} not found in cache")
    raise "TODO: we need to pass the client"
    # {:ok, result} =
    #   Task.async(fn -> GitHubApp.project_info(name_with_owner) end)
    #   |> Task.await()

    # store_result(
    #   result,
    #   name_with_owner,
    #   table
    # )
  end

  # defp store_result({:error, reason}, name_with_owner, table) do
  #   :ets.insert(table, {name_with_owner, {:error, reason}})
  #   {:error, reason}
  # end

  # defp store_result(project_data, name_with_owner, table) do
  #   :ets.insert(table, {name_with_owner, {:ok, project_data}})
  #   {:ok, project_data}
  # end
end
