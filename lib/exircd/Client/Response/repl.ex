defmodule ExIRCd.Client.Response.Repl do
  @moduledoc """
  Generic functions to template reply responses to IRC commands.
  """
  alias ExIRCd.Client.Message, as: Message

  @name hd(tl(String.split(to_string(Node.self), "@")))

  @doc """
  RPL_WELCOME response.
  """
  def r001(user) do
    prefix = "#{user.nick}!#{user.user}@#{user.rdns}"
    %Message{prefix: @name, command: "001", args: [user.nick], trailing: "Welcome to ExIRCd #{prefix}"}
  end

  @doc """
  RPL_YOURHOST response.
  """
  def r002(nick) do
    {:ok, vsn} = :application.get_key(:exircd, :vsn)
    %Message{prefix: @name, command: "002", args: [nick], trailing: "Your host is #{@name}, running version #{vsn}"}
  end

  @start_date :calendar.universal_time()
  @doc """
  RPL_CREATED response.
  """
  def r003(nick) do
    {{year, month, day}, {hour, minute, second}} = @start_date
    date = "#{to_string month}/#{to_string day}/#{to_string year} at #{to_string hour}:#{to_string minute}:#{to_string second}"
    %Message{prefix: @name, command: "003", args: [nick], trailing: "This server was created #{date}"}
  end

  @doc """
  RPL_MYINFO response.
  """
  def r004(nick) do
    {:ok, vsn} = :application.get_key(:exircd, :vsn)
    usermodes = "riw"
    channelmodes = "kbi"
    %Message{prefix: @name, command: "004", args: [nick], trailing: "#{@name} #{vsn} #{usermodes} #{channelmodes}"}
  end

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
  def r366(nick, chan) do
    %Message{prefix: @name, command: "366", args: [nick, chan], trailing: "End of /NAMES list."}
  end

  @doc """
  RPL_MOTDSTART response.
  """
  def r375(nick, chan) do
    %Message{prefix: @name, command: "366", args: [nick, chan], trailing: "End of /NAMES list."}
  end

end
