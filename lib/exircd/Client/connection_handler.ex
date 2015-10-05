defmodule ExIRCd.Client.ConnHandler do
  @moduledoc """
  Connection handler. This serves to handle the raw socket from a client, passing messages
  to the connection server and receiving messages from it. Upon initialization it will
  send a message to the connection server informing it of the agent being updated so
  that normal operation may begin between both .
  """
  require Logger

  def start_link(agent, acceptor) do
    GenServer.start_link(__MODULE__, [agent, acceptor])
  end

  def init([agent, acceptor]) do
    send self(), {:ready}
    {:ok, {agent, acceptor}}
  end

  @doc """
  Accepts a cast from the connection server and sends the message to
  the client.
  """
  def handle_cast({:send, message}, {agent}) do
    %{:conn => conn} = Agent.get(agent, fn map -> map end)
    Socket.Stream.send! conn, message
    {:noreply, {agent}}
  end

  @doc """
  Informs the connection server and acceptor that the handler is ready to
  be utilized. It is the first callback triggered after init/1 is completed.

  In addition, if the socket handler has somehow crashed previously, it will detect
  this and force a shutdown of the entire function.
  """
  def handle_info({:ready}, {agent, acceptor}) do
    Logger.log :debug, "Connection handler sending registration to acceptor"
    case Agent.get(agent, fn map -> map end) do
      %{:handler => _handler, :server => server} ->
        Logger.log :warn, "Connection handler was started abnormally, shutting down"
        send server, {:socket_closed}
        {:noreply, {agent}}
      %{:server => server} ->
        s = self()
        Agent.update(agent, fn map -> Dict.put(map, :handler, s) end)
        send acceptor, self()
        send server, :handler_ready
        {:noreply, {agent}}
    end
  end

  @doc """
  Handles the acknowledge message from the socket, setting it as active.
  """
  def handle_info({ Reagent, :ack }, {agent}) do
    %{:conn => conn} = Agent.get(agent, fn map -> map end)
    conn |> Socket.active!
    { :noreply, {agent}}
  end

  @doc """
  Handles an incoming message from the client, sending it to the server.
  """
  def handle_info({ :tcp, _, message }, {agent}) do
    %{:server => server} = Agent.get(agent, fn map -> map end)
    GenServer.cast(server, {:recv, message})
    { :noreply, {agent}}
  end

  @doc """
  Handles the client closing the socket telling the server to do a full shutdown.
  """
  def handle_info({ :tcp_closed, _ }, {agent}) do
    %{:server => server} = Agent.get(agent, fn map -> map end)
    send server, {:socket_closed}
    { :noreply, {agent}}
  end
end
