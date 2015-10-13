defmodule ExIRCd do
  @moduledoc """
  Begins the execution of the ExIRCd server.
  """
  use Application

  def start(_type, _args) do
    tree = [worker(ExIRCd.Repo)]
    opts = [strategy: :one_for_one]
    Supervisor.start(tree, opts)
    {:ok, _pid} = ExIRCd.SuperSup.start_link
    Reagent.start ExIRCd.Acceptor, port: 6666
  end
end
