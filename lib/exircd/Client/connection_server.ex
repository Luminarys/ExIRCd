defmodule ExIRCd.Client.ConnServer do
  @moduledoc"""
  The connection server manages an individual connection. It has its own set of modules and will
  hold state information about the connection, such as channels joined, etc.

  It is created from the connection supervisor and given the acceptor pid, the connection, the 
  connection supervisor pid, and the super server pid.
  """
  require Logger
  use GenServer

  def start_link(acceptor, sup, conn) do
    Logger.log :debug, "Connection server started!"
    GenServer.start_link __MODULE__, [acceptor, sup, conn]
  end

  def init([acceptor, sup, conn]) do
    send self(), {:start_handler}
    {:ok, {acceptor, sup, conn}}
  end

  def handle_cast({:recv, message}, {sup, handler}) do
    GenServer.cast(handler, {:send, message})
    {:noreply, {sup, handler}}
  end

  import Supervisor.Spec

  def handle_info({:start_handler}, {acceptor, sup, conn}) do
    Logger.log :debug, "Connection server spawning connection handler supervisor!"
    handler = supervisor(ExIRCd.Client.ConnHandlerSup, [acceptor, conn, self()], restart: :transient)
    Supervisor.start_child(sup, handler)
    {:noreply, {sup, conn}}
  end

  def handle_info({:link, handler}, {sup, _conn}) do
    Logger.log :debug, "Connection server received link from handler"
    send self(), {:register}
    {:noreply, {sup, handler}}
  end

  def handle_info({:register}, {sup, handler}) do
    # Register the connection with the superserver
    {:noreply, {sup, handler}}
  end

  def handle_info({:socket_closed}, {sup, handler}) do
    ExIRCd.ConnSuperSup.close_connection sup
    {:noreply, {sup, handler}}
  end
end
