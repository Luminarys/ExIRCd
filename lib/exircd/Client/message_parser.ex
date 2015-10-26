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
  def parse_raw_to_message(raw, user) do
    require Pipe
    try do
      Pipe.pipe_matching val, {:ok, val},
      {:ok, {raw, user}}
      |> check_clrf
      |> remove_prefix
      |> get_args_and_trailing
      |> make_message
    rescue
      _ in MatchError -> {:error, :failed_to_match}
    end
  end

  defp check_clrf({raw, user}) do
      case String.ends_with? raw, "\r\n" do
        true -> {:ok, {String.rstrip(raw), user}}
        false -> {:error, :improper_ending}
      end
  end

  defp remove_prefix({raw, user}) do
    case String.starts_with? raw, ":" do
      true ->
        [":" <> _prefix, rest] = String.split(raw, " ", parts: 2)
        {:ok, {rest, user}}
      false ->
        {:ok, {raw, user}}
    end
  end

  defp get_args_and_trailing({raw, user}) do
    case String.contains? raw, ":" do
      true ->
        [args, trailing] = String.split(String.rstrip(raw), " :", parts: 2)
        [command|arg_list] = String.split(args)
        {:ok, {command, arg_list, trailing, user}}
      false ->
        [command|arg_list] = String.split(String.rstrip(raw))
        {:ok, {command, arg_list, "", user}}
    end
  end

  defp make_message({command, arg_list, trailing, user}) do
    prefix = "#{user.nick}!#{user.user}@#{user.rdns}"
    {:ok, %Message{prefix: prefix, command: command, args: arg_list, trailing: trailing}}
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
    case message.prefix do
      "" -> {"#{message.command} ", message}
      prefix -> {":#{prefix} #{message.command} ", message}
    end
  end

  defp add_args({raw, message}) do
    case message.args do
      [] -> {raw, message}
      args -> {"#{raw}#{Enum.join(args, " ")} ", message}
    end
  end

  defp add_trailing({raw, message}) do
    case message.trailing do
      "" -> "#{raw}\r\n"
      trailing -> "#{raw}:#{trailing}\r\n"
    end
  end
end
