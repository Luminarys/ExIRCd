defmodule ExIRCd.Client.ConnInterface do
  @moduledoc """
  The connection interface acts as an external interface for communication
  with other processes. It relays messages from the an external source to
  the conn server and vice versa. It essentially acts as a permanent
  external interface so that pids never have to be re-registered
  if they are ever stored externally.
  """
  require Logger
  use GenServer

  @doc """
  Starts the connection handler using the acceptor and agent.
  """
  def start_link(agent) do
    Logger.log :debug, "External handler started"
    GenServer.start_link(__MODULE__, [agent])
  end

  @doc """
  Initializes the handler by sending itself `:ready` which will
  be the first callback triggerde by GenServer.
  """
  def init([agent]) do
    send self(), {:ready}
    {:ok, {agent}}
  end

  @doc """
  Handle a call from the super server.
  """
  def handle_call({:super_server_msg, message}, _from, {agent}) do
    {:reply, :ok, {agent}}
  end

  @doc """
  Handle a call from another client.
  """
  def handle_call({:client_msg, message}, _from, {agent}) do
    {:reply, :ok, {agent}}
  end

  @doc """
  Handle a cast from the super server.
  """
  def handle_cast({:super_server_msg, message}, _from, {agent}) do
    {:noreply, {agent}}
  end

  @doc """
  Handle a cast from another client.
  """
  def handle_cast({:client_msg, message}, _from, {agent}) do
    {:noreply, {agent}}
  end

  @doc """
  Informs the connection server that the connection interface is ready to be used.
  It is the first callback triggered after init/1 is completed.

  In addition, if the interface handler has somehow crashed previously, it will detect
  this and force a shutdown of the entire function.
  """
  def handle_info({:ready}, {agent}) do
    case Agent.get(agent, fn map -> map end) do
      %{:interface => _interface, :server => server} ->
        Logger.log :warn, "External Interface was started abnormally, shutting down"
        send server, {:socket_closed}
        {:noreply, {agent}}
      %{:server => server} ->
        s = self()
        Agent.update(agent, fn map -> Dict.put(map, :interface, s) end)
        :ok = GenServer.call(server, :interface_ready)
        {:noreply, {agent}}
    end
  end
end
