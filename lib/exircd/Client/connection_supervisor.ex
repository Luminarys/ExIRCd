defmodule ExIRCd.Client.ConnSup do
  @moduledoc """
  Connection Supervisor. This supervisor manages an individual connection,
  which includes a connection server and a connection handler supervisor
  and connection handler.
  
  
  The connection supervisor is initially called with the connection, and the
  acceptor pid. It passes these as well as its own pid to the connection
  server. The connection server will init, and send itself a message which
  will cause it to tell the connection supervisor to spawn the connection
  handler supervisor using the connection, acceptor pid, and connection server pid.
  """
  use Supervisor

  def start_link(acceptor, conn) do
    Supervisor.start_link(__MODULE__, [acceptor, conn])
  end

  def start_link() do
    {:error, {:shutdown, "Server must be started with the acceptor and connection pids"}}
  end

  def init([acceptor, conn]) do
    IO.puts "New conn sup initialized!"
    children = [
      worker(ExIRCd.Client.ConnServer, [acceptor, self(), conn], restart: :transient),
      # supervisor(ExIRCd.Client.ConnHandlerSup, [], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
