defmodule ExIRCd.Client.ConnServer do
  @moduledoc"""
  The connection server manages an individual connection. It has its own set of modules and will
  hold state information about the connection, such as channels joined, etc.

  It is created from the connection supervisor and given the acceptor pid, the connection, the 
  connection supervisor pid, and the super server pid.
  """
  require Logger
  use GenServer

  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.MessageParser, as: MessageParser

  defmodule User do
    defstruct nick: "", name: "", rdns: "", ip: "", secure: false, channels: []
  end

  def start_link(acceptor, sup, conn) do
    Logger.log :debug, "Connection server started!"
    GenServer.start_link __MODULE__, [acceptor, sup, conn]
  end

  def init([acceptor, sup, conn]) do
    send self(), {:start_handler}
    Logger.log :debug, "Connection server initialized"
    {:ok, {acceptor, sup, conn, %User{}}}
  end

  def handle_cast({:recv, message}, {sup, handler, user}) do
    case MessageParser.parse_raw_to_message(message) do
      {:ok, m} ->
        GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(m)})
        {:noreply, {sup, handler, user}}
      {:error, error} ->
        Logger.log :warn, "User input was not properly formatted"
        {:noreply, {sup, handler, user}}
    end
  end

  import Supervisor.Spec

  def handle_info({:start_handler}, {acceptor, sup, conn, user}) do
    Logger.log :debug, "Connection server spawning connection handler supervisor!"
    handler = supervisor(ExIRCd.Client.ConnHandlerSup, [acceptor, conn, self()], restart: :transient)
    Supervisor.start_child(sup, handler)
    {:noreply, {sup, conn, user}}
  end

  def handle_info({:link, handler}, {sup, conn, user}) do
    Logger.log :debug, "Connection server received link from handler"
    send self(), {:register}
    {:ok, {ip, _port}} = Socket.local conn
    # TODO: rDNS query, SSL check, ban check
    GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(%Message{command: 439, args: ["*"], trailing: "Please wait while we process your connection."})})
    {:noreply, {sup, handler, %{user | ip: ip, rdns: "temp_rdns"}}}
  end

  def handle_info({:register}, {sup, handler, user}) do
    # Register the connection with the superserver
    {:noreply, {sup, handler, user}}
  end

  def handle_info({:socket_closed}, {sup, handler, user}) do
    ExIRCd.ConnSuperSup.close_connection sup
    {:noreply, {sup, handler, user}}
  end
end
