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
                    %{:user => user, :server => server} ->
                      case user do
                        %{:registered => true} -> :ok
                        %{:registered => false} ->
                          GenServer.cast server, {:close_conn, "Registration timed out"}
                      end
                  end
                end
              end)
    {:reply, :ok, {agent}}
  end

  def handle_call(:interface_ready, _from, {agent}) do
    {:reply, :ok, {agent}}
  end

  @doc """
  Handles a received message from the connection interfaces,
  sending it to the handler for transmission to the client.
  """
  def handle_call({:send, message}, _from, {agent}) do
    %{:handler => handler} = Agent.get(agent, fn map -> map end)
    :ok = GenServer.call(handler, {:send, MessageParser.parse_message_to_raw(message)})
    {:reply, :ok, {agent}}
  end


  @doc """
  Handles a received message from the connection handler.
  The message is parsed into the proper struct and then handled.
  """
  def handle_cast({:recv, raw_message}, {agent}) do
    require Pipe

    Pipe.pipe_matching {:ok, _},
    {:ok, {raw_message, agent}}
    |> parse_message
    |> find_command
    |> execute_command
  end

  @doc """
  Handles a received message from the connection interfaces,
  sending it to the handler for transmission to the client.
  """
  def handle_cast({:send, message}, {agent}) do
    %{:handler => handler} = Agent.get(agent, fn map -> map end)
    :ok = GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(message)})
    {:noreply, {agent}}
  end

  @doc """
  Terminates the connection with reason `reason`. Used for ping timeouts etc.
  """
  def handle_cast({:close_conn, reason}, {agent}) do
    %{:sup => sup, :handler => handler, :user => user} = Agent.get(agent, fn map -> map end)
    GenServer.call ExIRCd.SuperServer.Server, {:remove_client, user.nick, user.channels}
    raw_message = MessageParser.parse_message_to_raw(%Message{command: "ERROR", args: [":Closing Link:", user.rdns, "(#{reason})"]})
    :ok = GenServer.call(handler, {:send, raw_message})
    ExIRCd.ConnSuperSup.close_connection sup
    {:reply, :ok, {agent}}
  end

  @doc """
  Handles the socket handler being closed, requesting that the connection
  supervisor and children be terminated.
  """
  def handle_info({:socket_closed}, {agent}) do
    %{:sup => sup, :user => user} = Agent.get(agent, fn map -> map end)
    #  :meme!~me@Rizon-B96C31FC.dhcp.stls.mo.charter.com QUIT :Remote host closed the connection
    GenServer.call ExIRCd.SuperServer.Server, {:remove_client, user.nick, user.channels}
    prefix = "#{user.nick}!#{user.user}@#{user.rdns}"
    quit_msg = %Message{prefix: prefix, command: "QUIT", args: [], trailing: "Remote host closed the connection"}
    for chan <- user.channels,
    do: GenServer.call ExIRCd.SuperServer.Server, {:send_to_chan, chan, quit_msg, user.nick}
    ExIRCd.ConnSuperSup.close_connection sup
    {:noreply, {agent}}
  end

  defp parse_message({:ok, {raw_message, agent}}) do
    %{:user => user} = Agent.get(agent, fn map -> map end)
    case MessageParser.parse_raw_to_message(raw_message, user) do
      {:ok, message} ->
        Logger.log :debug, "Received message: #{String.rstrip raw_message}"
        {:ok, {message, agent}}
      {:error, _error} ->
        Logger.log :debug, "User input was not properly formatted"
        {:noreply, {agent}}
    end
  end

  defp find_command({:ok, {message, agent}}) do
    %{:commands => commands} = Agent.get(agent, fn map -> map end)
    case Enum.find(commands, :nomatch, fn cmd -> cmd.check(message, agent) end) do
      :nomatch ->
        {:noreply, {agent}}
      command ->
        {:ok, {&command.parse/2, message, agent}}
    end
  end

  defp execute_command({:ok, {parser, message, agent}}) do
    case parser.(message, agent) do
      {:ok, nil} ->
        {:noreply, {agent}}
      {:error, errMsg} ->
        %{:handler => handler} = Agent.get(agent, fn map -> map end)
        GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(errMsg)})
        {:noreply, {agent}}
    end
  end
end
