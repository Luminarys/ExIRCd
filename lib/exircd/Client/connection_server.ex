defmodule ExIRCd.Client.ConnServer do
  @moduledoc"""
  The connection server manages an individual connection. It has its own set of modules and will
  hold state information about the connection, such as channels joined, etc.

  It is created from the connection supervisor and given the agent.
  """
  require Logger
  use GenServer

  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.MessageParser, as: MessageParser

  defmodule User do
    defstruct user: "", nick: "", name: "", rdns: "", ip: "", modes: [] ,channels: []
  end

  def start_link(agent) do
    Logger.log :debug, "Connection server started!"
    GenServer.start_link __MODULE__, [agent]
  end

  def init([agent]) do
    Logger.log :debug, "Connection server initialized"
    s = self()
    Agent.update(agent, fn map -> Dict.put(map, :server, s) end)
    Agent.update(agent, fn map -> Dict.put(map, :user, %User{}) end)
    send self(), {:start_conn}
    {:ok, {agent}}
  end

  @doc """
  Handles a received message from the connection handler.
  The message is parsed into the proper struct and then handled.
  """
  def handle_cast({:recv, raw_message}, {agent}) do
   %{:user => user} = Agent.get(agent, fn map -> map end)
    case MessageParser.parse_raw_to_message(raw_message, user) do
      {:ok, message} ->
        case Agent.get(agent, fn map -> map end) do
          %{:imods => [next_mod|_mods_left], :ready => false} ->
            if :ok == next_mod.parse(message, agent) do
              ExIRCd.Client.InitModule.removeMod(agent)
            {:noreply, {agent}}
            else
            {:noreply, {agent}}
            end
          %{:ready => true} ->
            {:noreply, {agent}}
        end
      {:error, _error} ->
        Logger.log :debug, "User input was not properly formatted"
        {:noreply, {agent}}
    end
  end

  @doc """
  Handles the startup message passed to self. If the handler is uninitialized,
  then this will wait until it gets a message of initialization, otherwise 
  """
  def handle_info({:start_conn}, {agent}) do
    # Wait for the connection handler to startup. Even if this fails we'll keep on erroring and restarting until it works
    case Agent.get(agent, fn map -> map end) do
      %{:conn => _conn, :handler => _handler, :user => _user} ->
        {:noreply, {agent}}
      %{:conn => conn, :user => user} ->
        receive do
          :handler_ready ->
            %{:handler => handler} = Agent.get(agent, fn map -> map end)
            {:ok, {ip, _port}} = Socket.local conn
            # TODO: rDNS query, SSL check, ban check
            GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(%Message{prefix: "ExIRCd@localhost", command: 439, args: ["*"], trailing: "Please wait while we process your connection."})})
            # TODO: Register with super server and being intialization
            Agent.update(agent, fn map -> Dict.put(map, :user, %{user | ip: ip, rdns: "temp_rdns"}) end)
            {:noreply, {agent}}
          _ ->
            send self(), {:start_conn}
            {:noreply, {agent}}
        end
    end
  end

  def handle_info({:socket_closed}, {agent}) do
    %{:sup => sup} = Agent.get(agent, fn map -> map end)
    ExIRCd.ConnSuperSup.close_connection sup
    {:noreply, {agent}}
  end
end
