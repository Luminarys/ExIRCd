defmodule ExIRCd.Acceptor do
  @moduledoc """
  Accepts connections from clients, spawns a connection supervisor, and then passes info to it.
  It then listens for a response from a connection handler.
  """
  use Reagent.Behaviour

  def start(conn) do
    IO.puts "Passing self and connection to ConnSuperSup"
    ExIRCd.ConnSuperSup.start_connection(self(), conn)       
    receive do
      pid -> 
        IO.puts "Acceptor received PID!"
        {:ok, pid}
    end
  end
end
