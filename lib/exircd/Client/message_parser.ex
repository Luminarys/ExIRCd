defmodule ExIRCd.Client.Message do
  @moduledoc """
  Representation of an IRC message in struct form.
  The trailing argument is the final argument, separated
  for convenience.
  """
  defstruct prefix: "", command: "", args: [], trailing: ""
end


defmodule ExIRCd.Client.MessageParser do
  @moduledoc """
  Module which contains the basic user input parsing commands.
  This is the only part of the system in which user input is validated.
  """
  alias ExIRCd.Client.Message, as: Message
  @doc """
  Converts a raw string into an IRC message.
  """
  def parse_raw_to_message(string) do
    try do
      case String.ends_with? string, "\r\n" do
        true ->
          [prefix, command, args] = String.split(string, " ", parts: 3)
          [ws_args, trailing] = String.split(String.rstrip(args), " :", parts: 2)
          arg_list = String.split(ws_args, " ")
          {:ok, %Message{prefix: prefix, command: command, args: arg_list, trailing: trailing}}
        false ->
          {:error, :improper_ending}
      end
    rescue
      e in MatchError -> {:error, :failed_to_match}
    end
  end

  @doc """
  Converts an IRC message into a string to be sent to a client.
  """
  def parse_message_to_raw(%Message{command: command, args: arg_list, trailing: trailing}) do
    host = "ExIRCd@localhost"
    ":#{host} #{command} #{Enum.join(arg_list, " ")} :#{trailing}\r\n"
  end
end
