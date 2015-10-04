defmodule ExIRCd do
  use Application
  
  def start(_type, _args) do
      {:ok, pid} = ExIRCd.SuperSup.start_link
      Reagent.start ExIRCd.Acceptor, port: 8080
  end
end
