defmodule ExIRCd.Client.Response.Repl do
  @moduledoc """
  Generic functions to template reply responses to IRC commands.
  """
  alias ExIRCd.Client.Message, as: Message

  @name hd(tl(String.split(to_string(Node.self), "@")))

  @doc """
  RPL_TOPIC response.
  """
  def r332(chan, topic) do
    %Message{prefix: @name, command: "332", args: [chan], trailing: topic}
  end

  @doc """
  RPL_TOPICWHOTIME response.
  """
  def r333(chan, person, time) do
    %Message{prefix: @name, command: "333", args: [chan, person, time]}
  end

  @doc """
  RPL_NAMREPLY response.
  """
  def r353(nick, chan_prefix, chan, users) do
    %Message{prefix: @name, command: "353", args: [nick, chan_prefix, chan], trailing: users}
  end

  @doc """
  RPL_ENDOFNAMES response.
  """
  def r366(chan) do
    %Message{prefix: @name, command: "366", args: [chan], trailing: "End of /NAMES list."}
  end

end
