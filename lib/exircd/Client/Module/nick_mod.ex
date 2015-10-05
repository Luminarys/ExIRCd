defmodule ExIRCd.Client.InitModule.NickModule do
  @behaviour ExIRCd.Client.InitModule
  alias ExIRCd.Client.Message, as: Message
  @moduledoc """
  Parses out the NICK message.
  """

  def parse(%Message{command: command, args: [nick]}, agent) do
    %{:user => user} = Agent.get(agent, fn map -> map end)
    acceptable_nicks = ~r"([a-zA-Z]|_|\\|\[|\]|\{|\}|\^|\`|\|)([a-zA-Z0-9]|_|-|\\|\[|\]|\{|\}|\^|\`|\|)*"
    [^nick|_othermatches] = Regex.run acceptable_nicks, nick
    # TODO: Verify this nick is unique, do registration, etc.
    nuser = %{user| nick: nick}
    :ok
  end
end
