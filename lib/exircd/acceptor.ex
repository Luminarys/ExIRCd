defmodule ExIRCd.Acceptor do
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

defmodule ExIRCd.AcceptorSup do
  @moduledoc """
  Supervises the socket acceptor process, ensuring that it stays up.
  """
end
