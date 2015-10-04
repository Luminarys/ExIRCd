defmodule ExIRCd.Acceptor do
  require Logger
  @moduledoc """
  Accepts connections from clients, spawns a connection supervisor, and then passes info to it.
  It then listens for a response from a connection handler.
  """
  use Reagent.Behaviour

  def start(conn) do
    Logger.log :debug, "Acceptor received new client connection. Adding new connection supervisor to the connection super supervisor"
    ExIRCd.ConnSuperSup.start_connection(self(), conn)       
    receive do
      pid -> 
        Logger.log :debug, "Acceptor received PID!"
        {:ok, pid}
    end
  end
end
