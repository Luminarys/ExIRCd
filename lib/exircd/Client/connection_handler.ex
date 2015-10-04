defmodule ExIRCd.Client.ConnHandlerSup do
  @moduledoc """
  Connection Handler Supervisor. This supervises the connection handler,
  which is what sends to and receives from the socket itself.

  The connection handler sup will start out with a template for a simple_one_for_one
   connection handler and  will be told to spawn a child from the connection server once it is ready.
  The child spawned will be given the connection, the acceptor pid, and the connection
  server pid.
  """
  require Logger
  use Supervisor
  
  def start_link(acceptor, connection, server) do
    Supervisor.start_link __MODULE__, [acceptor, connection, server] 
  end

  def init([acceptor, connection, server]) do
    Logger.log :debug, "New connection handler supervisor started!"
    children = [
      supervisor(ExIRCd.Client.ConnHandler, [acceptor, connection, server], restart: :transient)
    ]

    supervise(children, strategy: :one_for_one)
  end
end

defmodule ExIRCd.Client.ConnHandler do
  @moduledoc """
  Connection handler. This serves to handle the raw socket from a client, passing messages
  to the connection server and receiving messages from it. Upon initialization it will
  send a message to the connection server informing it of its pid so that a proper link
  may be established between the handler and server
  """
  require Logger

  def start_link(acceptor, connection, server) do
    GenServer.start_link(__MODULE__, [acceptor, connection, server])
  end

  def init([acceptor, connection, server]) do
    send self(), {:ready}
    {:ok, {acceptor, connection, server}}
  end

  def handle_info({:ready}, {acceptor, connection, server}) do
    Logger.log :debug, "Connection handler sending registration to acceptor and connection server"
    send acceptor, self()
    send server, {:link, self()}
    {:noreply, {connection, server}}
  end

  def handle_info({ Reagent, :ack }, {connection, server}) do
    connection |> Socket.active!
    { :noreply, {connection, server}}
  end

  def handle_info({ :tcp, _, data }, {connection, server}) do
    connection |> Socket.Stream.send! data

    { :noreply, {connection, server}}
  end

  def handle_info({ :tcp_closed, _ }, {connection, server}) do
    send server, {:socket_closed}
    { :noreply, {connection, server}}
  end
end
