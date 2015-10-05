defmodule ExIRCd.Client.InitModule do
  @moduledoc """
  A module which deals with client connection initialization.
  A InitModule may perform tasks like checking for passwords,
  displaying the welcome message, and moer.
  """
  use Behaviour
  require Logger
  defcallback parse(%ExIRCd.Client.Message{}, Agent.t) :: any 

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
