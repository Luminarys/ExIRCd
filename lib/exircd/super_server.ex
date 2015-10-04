defmodule ExIRCd.SuperServer do
end

defmodule ExIRCd.SuperServerSup do
  require Logger
  @moduledoc """
  Launches and supervises the super server, ensuring that it stays up.
  """
  @super_server_name ExIRCd.SuperServer.Server

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      worker(ExIRCd.SuperServer.Server, [[name: @super_server_name]], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_one)
  end
end

