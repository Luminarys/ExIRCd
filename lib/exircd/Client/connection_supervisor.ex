defmodule ExIRCd.Client.ConnSup do
  @moduledoc """
  Connection Supervisor. This supervisor manages an individual connection,
  which includes a connection server and a connection handler.
  
  The connection supervisor is initially called with the connection, and the
  acceptor pid. The supervisor first creates the connection server which registers
  its pid in the shared agent. The connection handler is then started, and adds its
  own pid to the shared agent and tells the connection server that it is properly
  initialized. At this point, normal operation begins between both.
  """
  use Supervisor
  require Logger

  def start_link(acceptor, conn) do
    Supervisor.start_link(__MODULE__, [acceptor, conn])
  end

  def start_link() do
    {:error, {:shutdown, "Server must be started with the acceptor and connection pids"}}
  end

  def init([acceptor, conn]) do
    Logger.log :debug, "New Connection Supervisor created!"
    # Agent is used to store state so that the handler and server may communicate easily
    {:ok, agent} = Agent.start_link fn -> %{} end
    Agent.update(agent, fn map -> Dict.put(map, :conn, conn) end)
    s = self()
    Agent.update(agent, fn map -> Dict.put(map, :sup, s) end)
    Agent.update(agent, fn map -> Dict.put(map, :ready, false) end)

    # TODO: Set this via configuration options
    alias ExIRCd.Client.InitModule, as: IMods
    imods = [IMods.UserModule, IMods.NickModule]
    Agent.update(agent, fn map -> Dict.put(map, :imods, imods) end)
    children = [
      worker(ExIRCd.Client.ConnServer, [agent], restart: :transient),
      worker(ExIRCd.Client.ConnHandler, [agent, acceptor], restart: :transient),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
