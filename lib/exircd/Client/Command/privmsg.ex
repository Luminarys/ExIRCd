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
    |> send_message(user.nick)
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

  defp send_message({:ok, {recip, message}}, nick) do
    # TODO: Check other servers
    case {:ets.lookup(:clients, recip), :ets.lookup(:channels, recip)} do
      {[], []} -> {:error, Response.Err.e401(recip)}
      {[{^recip, client}], []} -> 
        GenServer.cast(client, {:client_msg, message})
        {:ok, nil}
      {[], [{^recip, _channel}]} ->
        GenServer.call ExIRCd.SuperServer.Server, {:send_to_chan, recip, message, nick}
        {:ok, nil}
    end
  end
end

