defmodule ExIRCd do
  @moduledoc """
  Begins the execution of the ExIRCd server.
  """
  use Application
  
  def start(_type, _args) do
      {:ok, _pid} = ExIRCd.SuperSup.start_link
      Reagent.start ExIRCd.Acceptor, port: 8080
  end
end
