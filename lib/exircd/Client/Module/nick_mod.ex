defmodule ExIRCd.Client.InitModule.NickModule do
  @behaviour ExIRCd.Client.InitModule
  alias ExIRCd.Client.Message, as: Message
  @moduledoc """
  Parses out the NICK message.
  """

  def check(%Message{command: command, args: _arg_list, trailing: _trailing}, _agent) do
    {command == "NICK", nil}
  end

  def parse(%Message{command: command, args: [nick]}, agent) do
    %{:user => user} = Agent.get(agent, fn map -> map end)
    acceptable_nicks = ~r"([a-zA-Z]|_|\\|\[|\]|\{|\}|\^|\`|\|)([a-zA-Z0-9]|_|-|\\|\[|\]|\{|\}|\^|\`|\|)*"
    [^nick|_othermatches] = Regex.run acceptable_nicks, nick
    # TODO: Verify this nick is unique, do registration, etc.
    nuser = %{user| nick: nick}
    Agent.update(agent, fn map -> Dict.put(map, :user, nuser) end)
    {:ok, nil}
  end
end
