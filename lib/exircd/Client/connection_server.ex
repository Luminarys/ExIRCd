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
    defstruct user: "", nick: "", name: "", rdns: "", ip: "", modes: [] ,channels: [], registered: false
  end

  @doc """
  Starts the connection server using the given agent.
  """
  def start_link(agent) do
    Logger.log :debug, "Connection server started!"
    GenServer.start_link __MODULE__, [agent]
  end

  @doc """
  Initializes the connection server, inserting its pid and the user struct
  into the agent. It also sends itself `:start_conn` to be run immediatly after
  initialization.
  """
  def init([agent]) do
    Logger.log :debug, "Connection server initialized"
    s = self()
    Agent.update(agent, fn map -> Dict.put(map, :server, s) end)
    Agent.update(agent, fn map -> Dict.put(map, :user, %User{}) end)
    {:ok, {agent}}
  end

  def handle_call(:handler_ready, _from, {agent}) do
    %{:conn => conn, :user => user} = Agent.get(agent, fn map -> map end)
    {:ok, {ip, _port}} = Socket.local conn
    # TODO: rDNS query, SSL check, ban check
    # TODO: Register with super server and being intialization
    Agent.update(agent, fn map -> Dict.put(map, :user, %{user | ip: ip, rdns: "temp_rdns"}) end)
    # Start registration timeout
    Task.start(fn ->
                :timer.sleep 15000
                if Process.alive? agent do
                  case Agent.get(agent, fn map -> map end) do
                    %{:ready => true} -> :ok
                    %{:ready => false, :server => server} ->
                      GenServer.cast server, {:close_conn, "Registration timed out"}
                  end
                end
              end)
    {:reply, :ok, {agent}}
  end

  def handle_call(:interface_ready, _from, {agent}) do
    {:reply, :ok, {agent}}
  end

  @doc """
  Handles a received message from the connection handler.
  The message is parsed into the proper struct and then handled.
  """
  def handle_cast({:recv, raw_message}, {agent}) do
   %{:user => user} = Agent.get(agent, fn map -> map end)
   Logger.log :debug, "Received message: #{String.rstrip raw_message}"
    case MessageParser.parse_raw_to_message(raw_message, user) do
      {:ok, message} ->
        case Agent.get(agent, fn map -> map end) do
          %{:imods => [next_mod|_mods_left], :ready => false, :handler => handler} ->
            case next_mod.parse(message, agent) do
              {:ok, nil} ->
                ExIRCd.Client.Command.removeMod(agent)
                {:noreply, {agent}}
              {:error, errMsg} ->
                :ok = GenServer.call(handler, {:send, MessageParser.parse_message_to_raw(errMsg)})
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
  Terminates the connection with reason `reason`. Used for ping timeouts etc.
  """
  def handle_cast({:close_conn, reason}, {agent}) do
    %{:sup => sup, :handler => handler, :user => user} = Agent.get(agent, fn map -> map end)
    raw_message = MessageParser.parse_message_to_raw(%Message{command: "ERROR", args: [":Closing Link:", user.rdns, "(#{reason})"]})
    :ok = GenServer.call(handler, {:send, raw_message})
    ExIRCd.ConnSuperSup.close_connection sup
    {:noreply, {agent}}
  end

  @doc """
  Handles the socket handler being closed, requesting that the connection
  supervisor and children be terminated.
  """
  def handle_info({:socket_closed}, {agent}) do
    %{:sup => sup} = Agent.get(agent, fn map -> map end)
    ExIRCd.ConnSuperSup.close_connection sup
    {:noreply, {agent}}
  end
end
