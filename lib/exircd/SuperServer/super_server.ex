defmodule ExIRCd.SuperServer.Server do
  @moduledoc """
  Performs server level tasks of delivering messages to connections,
  and updates to the SQL server. All messages will pass through this
  if they want to either alter the server state or be sent to other
  clients.
  """
  use GenServer
  
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(_opts) do
    {:ok, {}}
  end
end

