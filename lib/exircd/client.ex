defmodule ExIRCd.Client do
end

defmodule ExIRCd.ConnSuperSup do
  require Logger
  @moduledoc """
  Connection Super Supervisor. This supervisor uses simple_one_for_one
  to create Connection Supervisor children which each manage their own
  connection. It knows the pid of the super server and passes it to all its
  children.

  It is called from the Acceptor which passes the acceptor's pid, and
  the new connection. Passing the acceptor pid allows the acceptor 
  to be sent the pid of the final process which holds the connection
  """
  
  use Supervisor
  
  @doc """
  Starts the connection super server with the given options.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Spawns a new connection supervisor. This is called by the Reagent Acceptor
  which passes the acceptor pid, and the connection.
  """
  def start_connection(acceptor, conn) do
    Logger.log :debug, "Connection Super Supervisor starting a Connection Supervisor"
    Supervisor.start_child(ExIRCd.ConnSuperSup, [acceptor, conn])
  end

  @doc """
  Terminates and removes a connection supervisor. This should be called after
  a client disconnects or is forcibly disconnected from the server
  """
  def close_connection(conn_sup) do
    Supervisor.terminate_child ExIRCd.ConnSuperSup, conn_sup
    Supervisor.delete_child ExIRCd.ConnSuperSup, conn_sup
  end

  def init(_opts) do
    children = [
      supervisor(ExIRCd.Client.ConnSup, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
