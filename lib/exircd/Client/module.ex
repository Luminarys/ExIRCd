defmodule ExIRCd.Client.InitModule do
  @moduledoc """
  A module which deals with client connection initialization.
  A InitModule may perform tasks like checking for passwords,
  displaying the welcome message, and moer.
  """
  use Behaviour
  require Logger

  @doc """
  Callback for an init module that takes a message, an agent, and
  returns :ok on success.
  """
  defcallback check(%ExIRCd.Client.Message{}, Agent.t) :: {true, any} | {false, any}

  @doc """
  Callback for parsing a message once it's been validated.
  """
  defcallback parse(%ExIRCd.Client.Message{}, Agent.t) :: {:ok, any} | {:failed, any}

  @doc """
  Removes an InitModule from a given agent and sets the ready state
  to true if all init modules have succesfully been removed.
  """
  def removeMod(agent) do
    %{:imods => imods} = Agent.get(agent, fn map -> map end)
    imods_left = tl(imods)
    Agent.update(agent, fn map -> Dict.put(map, :imods, imods_left) end)
    if imods_left == [] do
      Logger.log :debug, "All init modules have been cleared, entering primary state"
      Agent.update(agent, fn map -> Dict.put(map, :ready, true) end)
    end
  end
end
