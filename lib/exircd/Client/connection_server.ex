defmodule ExIRCd.Client.ConnServer do
  @moduledoc"""
  The connection server manages an individual connection. It has its own set of modules and will
  hold state information about the connection, such as channels joined, etc.

  It is created from the connection supervisor and given the acceptor pid, the connection, the 
  connection supervisor pid, and the super server pid.
  """
  use GenServer

  def start_link(acceptor, sup, conn) do
    IO.puts "Connection server started!"
    GenServer.start_link __MODULE__, [acceptor, sup, conn]
  end

  def init([acceptor, sup, conn]) do
    send self(), {:start_handler}
    {:ok, {acceptor, sup, conn}}
  end

  import Supervisor.Spec

  def handle_info({:start_handler}, {acceptor, sup, conn}) do
    IO.puts "Connection server performing ConnHandlerSup init!"
    handler = supervisor(ExIRCd.Client.ConnHandlerSup, [acceptor, conn, self()], restart: :transient)
    Supervisor.start_child(sup, handler)
    {:noreply, {acceptor, sup, conn}}
  end

  def handle_info({:link, handler}, {_acceptor, sup, conn}) do
    IO.puts "Connection server received link from handler"
    send self(), {:register}
    {:noreply, {handler, sup, conn}}
  end

  def handle_info({:register}, {handler, sup, conn}) do
    # Register the connection with the superserver
    {:noreply, {handler, sup, conn}}
  end

  def handle_info({:shutdown}, {handler, sup, conn}) do
    Process.exit(sup, :normal)
    {:noreply, {handler, sup, conn}}
  end
end

