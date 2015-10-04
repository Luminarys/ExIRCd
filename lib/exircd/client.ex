defmodule ExIRCd.Client do
end

defmodule ExIRCd.ConnSuperSup do
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
  
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_connection(acceptor, conn) do
    IO.puts "Starting a Connection Supervisor"
    IO.inspect Supervisor.start_child(ExIRCd.ConnSuperSup, [acceptor, conn])
  end

  def init(_opts) do
    children = [
      supervisor(ExIRCd.Client.ConnSup, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
