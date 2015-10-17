defmodule ExIRCd.Client.Response.Err do
  @moduledoc """
  Generic functions to template error responses to IRC commands.
  """
  alias ExIRCd.Client.Message, as: Message

  @name hd(tl(String.split(to_string(Node.self), "@")))

  @doc """
  ERR_NOSUCHNICK response.
  """
  def e401(recip) do
    %Message{prefix: @name, command: "401", args: [recip], trailing: "No such nick/channel"}
  end

  @doc """
  ERR_NOSUCHCHANNEL response.
  """
  def e403(chan) do
    %Message{prefix: @name, command: "403", args: [chan], trailing: "No such channel"}
  end

  @doc """
  ERR_CANNOTSENDTOCHAN response.
  """
  def e404(chan) do
    %Message{prefix: @name, command: "404", args: [chan], trailing: "Cannot send to channel"}
  end

  @doc """
  ERR_NORECIPIENT response.
  """
  def e411() do
    %Message{prefix: @name, command: "412", args: [], trailing: "No recipient given"}
  end

  @doc """
  ERR_NOTEXTOSEND response.
  """
  def e412() do
    %Message{prefix: @name, command: "412", args: [], trailing: "No text to send"}
  end

  @doc """
  ERR_NEEDNONICKNAMEGIVEN response.
  """
  def e431() do
    %Message{prefix: @name, command: "431", args: ["*"], trailing: "No nickname given"}
  end

  @doc """
  ERR_ERRONEUSNICKNAME response.
  """
  def e432(nick) do
    %Message{prefix: @name, command: "432", args: ["*", nick], trailing: "Erroneous nickname"}
  end

  @doc """
  ERR_NICKNAMEINUSE response.
  """
  def e433(nick) do
    %Message{prefix: @name, command: "433", args: ["*", nick], trailing: "Nickname is already in use."}
  end

  @doc """
  ERR_NOTONCHANNEL response.
  """
  def e442(chan) do
    %Message{prefix: @name, command: "442", args: [chan], trailing: "You're not on that channel"}
  end

  @doc """
  ERR_NOTREGISTERED response.
  """
  def e451() do
    %Message{prefix: @name, command: "451", args: ["*"], trailing: "Register first."}
  end

  @doc """
  ERR_NEEDMOREPARAMS response.
  """
  def e461(reason) do
    %Message{prefix: @name, command: "461", args: ["*","USER"], trailing: reason}
  end

  @doc """
  ERR_ALREADYREGISTRED response.
  """
  def e462(reason) do
    %Message{prefix: @name, command: "462", args: ["*","USER"], trailing: reason}
  end

  @doc """
  ERR_CHANNELISFULL response.
  """
  def e471(chan) do
    %Message{prefix: @name, command: "471", args: [chan], trailing: "Cannot join channel (+l)"}
  end

  @doc """
  ERR_INVITEONLYCHAN response.
  """
  def e473(chan) do
    %Message{prefix: @name, command: "473", args: [chan], trailing: "Cannot join channel (+i)"}
  end

  @doc """
  ERR_BANNEDFROMCHAN response.
  """
  def e474(chan) do
    %Message{prefix: @name, command: "474", args: [chan], trailing: "Cannot join channel (+b)"}
  end

  @doc """
  ERR_BADCHANNELKEY response.
  """
  def e475(chan) do
    %Message{prefix: @name, command: "475", args: [chan], trailing: "Cannot join channel (+k)"}
  end

  @doc """
  ERR_RESTRICTED response.
  """
  def e484() do
    %Message{prefix: @name, command: "484", args: ["*"], trailing: "Your connection is restricted!"}
  end
end
