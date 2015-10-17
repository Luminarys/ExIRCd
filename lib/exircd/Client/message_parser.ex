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
  def parse_raw_to_message(string, user) do
    try do
      case String.ends_with? string, "\r\n" do
        true ->
          case String.starts_with? string, ":" do
            true ->
              [":" <> _prefix, cargs] = String.split(string, " ", parts: 2)
              parse_clean_to_message(cargs, user)
            false ->
              parse_clean_to_message(string, user)
          end
        false ->
          {:error, :improper_ending}
      end
    rescue
      _ in MatchError -> {:error, :failed_to_match}
    end
  end

  defp parse_clean_to_message(cargs, user) do
    case String.contains? cargs, ":" do
      true ->
        [cargs, trailing] = String.split(String.rstrip(cargs), " :", parts: 2)
        [command|arg_list] = String.split(cargs)
        prefix = "#{user.nick}!#{user.user}@#{user.rdns}"
        {:ok, %Message{prefix: prefix, command: command, args: arg_list, trailing: trailing}}

      false ->
        [command|arg_list] = String.split(String.rstrip(cargs))
        prefix = "#{user.nick}!#{user.user}@#{user.rdns}"
        {:ok, %Message{prefix: prefix, command: command, args: arg_list}}
    end
  end

  @doc """
  Converts an IRC message into a string to be sent to a client.
  """
  def parse_message_to_raw(message) do
    message
    |> add_prefix
    |> add_args
    |> add_trailing
  end

  defp add_prefix(message) do
    %Message{prefix: prefix, command: command} = message
    case prefix do
      "" -> {"#{command} ", message}
      _ -> {":#{prefix} #{command} ", message}
    end
  end

  defp add_args({raw, message}) do
    %Message{args: args} = message
    case args do
      [] -> {raw, message}
      _ -> {"#{raw}#{Enum.join(args, " ")} ", message}
    end
  end

  defp add_trailing({raw, message}) do
    %Message{trailing: trailing} = message
    case trailing do
      "" -> "#{raw}\r\n"
      _ -> "#{raw}:#{trailing}\r\n"
    end
  end
end
