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
    defstruct nick: "", name: "", rdns: "", ip: "", secure: false, channels: []
  end

  def start_link(agent) do
    Logger.log :debug, "Connection server started!"
    GenServer.start_link __MODULE__, [agent]
  end

  def init([agent]) do
    Logger.log :debug, "Connection server initialized"
    s = self()
    Agent.update(agent, fn map -> Dict.put(map, :server, s) end)
    send self(), {:start_conn}
    {:ok, {agent, %User{}}}
  end

  def handle_cast({:recv, message}, {agent, user}) do
    case MessageParser.parse_raw_to_message(message) do
      {:ok, m} ->
        %{:handler => handler} = Agent.get(agent, fn map -> map end)
        GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(m)})
        {:noreply, {agent, user}}
      {:error, _error} ->
        Logger.log :warn, "User input was not properly formatted"
        {:noreply, {agent, user}}
    end
  end

  def handle_info({:start_conn}, {agent, user}) do
    # Wait for the connection handler to startup. Even if this fails we'll keep on erroring and restarting until it works
    :timer.sleep(150)
    %{:conn => conn, :handler => handler} = Agent.get(agent, fn map -> map end)
    {:ok, {ip, _port}} = Socket.local conn
    # TODO: rDNS query, SSL check, ban check
    GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(%Message{command: 439, args: ["*"], trailing: "Please wait while we process your connection."})})
    # TODO: Register with super server and being intialization
    {:noreply, {agent, %{user | ip: ip, rdns: "temp_rdns"}}}
  end

  def handle_info({:socket_closed}, {agent, user}) do
    %{:sup => sup} = Agent.get(agent, fn map -> map end)
    ExIRCd.ConnSuperSup.close_connection sup
    {:noreply, {agent, user}}
  end
end
