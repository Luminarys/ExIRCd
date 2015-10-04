defmodule ExIRCd.SuperSup do
  @moduledoc """
  The super supervisor creates the primary supervisors: super server supervisor,
  acceptor supervisor, and connection super supervisor.

  The super server supervisor is initially started and launches the super server supervisor,
  the connection super supervisor, and the acceptor supervisor in that order.

  If any one of these three supervisors ends up dying, the entire server will be restarted.
  """
  use Supervisor
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @conn_super_sup_name ExIRCd.ConnSuperSup
  def init(_opts) do
    children = [
      supervisor(ExIRCd.SuperServerSup, [], restart: :permanent),
      supervisor(ExIRCd.ConnSuperSup, [[name: @conn_super_sup_name]], restart: :permanent),
      #supervisor(ExIRCd.AcceptorSup, [], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
