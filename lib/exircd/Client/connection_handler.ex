defmodule ExIRCd.Client.ConnHandler do
  @moduledoc """
  Connection handler. This serves to handle the raw socket from a client, passing messages
  to the connection server and receiving messages from it. Upon initialization it will
  send a message to the connection server informing it of its pid so that a proper link
  may be established between the handler and server
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
  """
  def handle_info({:ready}, {agent, acceptor}) do
    Logger.log :debug, "Connection handler sending registration to acceptor"
      case Agent.get(agent, fn map -> map end) do
        %{:handler => handler, :server => server} ->
          Logger.log :warn, "Connection handler was started abnormally, shutting down"
          send server, {:socket_closed}
          {:noreply, {agent}}
        _ ->
          s = self()
          Agent.update(agent, fn map -> Dict.put(map, :handler, s) end)
          send acceptor, self()
          {:noreply, {agent}}
    end
  end

  def handle_info({ Reagent, :ack }, {agent}) do
    %{:conn => conn} = Agent.get(agent, fn map -> map end)
    conn |> Socket.active!
    { :noreply, {agent}}
  end

  def handle_info({ :tcp, _, message }, {agent}) do
    %{:server => server} = Agent.get(agent, fn map -> map end)
    GenServer.cast(server, {:recv, message})
    { :noreply, {agent}}
  end

  def handle_info({ :tcp_closed, _ }, {agent}) do
    %{:server => server} = Agent.get(agent, fn map -> map end)
    send server, {:socket_closed}
    { :noreply, {agent}}
  end
end
