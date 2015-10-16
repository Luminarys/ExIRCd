defmodule ExIRCd.Client.Command.PrivMsg do
  @behaviour ExIRCd.Client.Command
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.Response, as: Response
  @moduledoc """
  Parses out the PRIVMSG message.
  """

  def check(%Message{command: command, args: _arg_list, trailing: _trailing}, _agent) do
    command == "PRIVMSG"
  end

  def parse(message, agent) do
    require Pipe

    %{:user => user} = Agent.get(agent, fn map -> map end)

    Pipe.pipe_matching {:ok, _},
    {:ok, {message, user}}
    |> check_registration
    |> check_args
    |> check_recipient(user.nick)
    |> send_message
  end

  defp check_registration({:ok, {message, user}}) do
    case user.registered do
      true ->
        {:ok, message}
      false ->
        {:error, Response.Err.e451}
    end
  end

  defp check_args({:ok, message}) do
    %Message{args: arg_list, trailing: trailing} = message
    case {arg_list, trailing} do
      {[], _} -> {:error, Response.Err.e411}
      {[_recip], ""} -> {:error, Response.Err.e412}
      {[recip], _msg} -> {:ok, {recip, message}}
      {[recip|_msg], _trailing} -> {:ok, {recip, message}}
      _ -> {:error, Response.Err.e461("Incorrect parameter number given")}
    end
  end

  defp check_recipient({:ok, {recip, message}}, nick) do
    # TODO: Check other servers
    case {:ets.lookup(:clients, recip), :ets.lookup(:channels, recip)} do
      {[], []} -> {:error, Response.Err.e401(recip)}
      {[{^recip, client}], []} -> {:ok, {[client], message}}
      {[], [{^recip, channel}]} ->
        case :ets.lookup(channel, nick) do
          [] -> {:error, Response.Err.e404(recip)}
          _ ->
            clients = :ets.foldl(fn {client, pid}, pids ->
              case client do
                ^nick -> pids
                _ -> [pid|pids]
              end
            end, [], channel)
            {:ok, {[clients], message}}
        end
    end
  end

  defp send_message({:ok, {recips, message}}) do
    for recip <- recips, do: GenServer.cast(recip, {:client_msg, message})
    {:ok, nil}
  end
end

