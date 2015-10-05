defmodule ExIRCd.Client.InitModule.UserModule do
  @behaviour ExIRCd.Client.InitModule
  alias ExIRCd.Client.Message, as: Message
  @moduledoc """
  Parses out the USER message setting user, name, and modes accordingly.
  """

  def parse(%Message{command: command, args: arg_list, trailing: trailing}, agent) do
    # Example USER command USER [username] [0 - no bit| 6 - wallop|8 - invis|] * :[real name]
    if command == "USER"  do
      [username, mask, _unused] = arg_list
      name = trailing
      %{:user => user} = Agent.get(agent, fn map -> map end)
      case mask do
        "0" ->
          nuser = %{user| user: username, name: name}
          Agent.update(agent, fn map -> Dict.put(map, :user, nuser) end)
          :ok
        "6" ->
          modes = Enum.uniq(user.modes ++ [:w])
          nuser = %{user| user: username, name: name, modes: modes}
          Agent.update(agent, fn map -> Dict.put(map, :user, nuser) end)
          :ok
        "8" ->
          modes = Enum.uniq(user.modes ++ [:i])
          nuser = %{user| user: username, name: name, modes: modes}
          Agent.update(agent, fn map -> Dict.put(map, :user, nuser) end)
          :ok
      end
    end
  end
end
