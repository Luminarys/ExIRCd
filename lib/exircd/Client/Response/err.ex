defmodule ExIRCd.Client.Response.Err do
  @moduledoc """
  Generic functions to template error responses to IRC commands.
  """
  alias ExIRCd.Client.Message, as: Message

  @doc """
  ERR_NEEDNONICKNAMEGIVEN response.
  """
  def e431() do
    %Message{prefix: "", command: "461", args: ["*"], trailing: "No nickname given"}
  end

  @doc """
  ERR_ERRONEUSNICKNAME response.
  """
  def e432(nick) do
    %Message{prefix: "", command: "461", args: ["*", nick], trailing: "Erroneous nickname"}
  end

  @doc """
  ERR_NICKNAMEINUSE response.
  """
  def e433(nick) do
    %Message{prefix: "", command: "461", args: ["*", nick], trailing: "Nickname is already in use."}
  end

  @doc """
  ERR_NEEDMOREPARAMS response.
  """
  def e461(reason) do
    %Message{prefix: "", command: "461", args: ["*","USER"], trailing: reason}
  end

  @doc """
  ERR_ALREADYREGISTRED response.
  """
  def e462(reason) do
    %Message{prefix: "", command: "462", args: ["*","USER"], trailing: reason}
  end

  @doc """
  ERR_RESTRICTED response.
  """
  def e484() do
    %Message{prefix: "", command: "461", args: ["*"], trailing: "Your connection is restricted!"}
  end
end
