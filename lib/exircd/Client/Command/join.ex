defmodule ExIRCd.Client.Command.Join do
  @behaviour ExIRCd.Client.Command
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.Response, as: Response
  alias ExIRCd.Client.MessageParser, as: MessageParser
  @moduledoc """
  Parses out the PART message.
  """

  def check(%Message{command: command, args: _arg_list, trailing: _trailing}, _agent) do
    command == "JOIN"
  end

  def parse(message, agent) do
    require Pipe

    %{:user => user} = Agent.get(agent, fn map -> map end)

    Pipe.pipe_matching {:ok, _},
    {:ok, {message, user}}
    |> check_registration
    |> check_args
    |> join_chans(agent)
  end

  defp check_registration({:ok, {message, user}}) do
    case user.registered do
      true ->
        {:ok, message}
      false ->
        {:error, Response.Err.e451}
    end
  end

  defp check_args({:ok, %Message{args: arg_list}}) do
    case arg_list do
      [] -> {:error, Response.Err.e461("Need more parameters")}
      # TODO: Keys
      # [chans|keys] -> {}
      [chans] -> {:ok, String.split(chans, ",")}
    end
  end

  defp join_chans({:ok, chans}, agent) do
    for chan <- chans, do: join_chan(chan, agent)
    {:ok, nil}
  end

  defp join_chan(chan, agent) do
    require Pipe

    res = Pipe.pipe_matching {:ok, _},
    {:ok, {chan, agent}}
    |> check_chan_name
    |> check_in_chan
    |> check_invited
    |> check_banned
    |> check_key
    |> check_limit
    |> register_client
    |> reply_topic
    |> reply_names

    case res do
      {:err, errMsg} -> 
        %{:handler => handler} = Agent.get(agent, fn map -> map end)
        GenServer.cast(handler, {:send, MessageParser.parse_message_to_raw(errMsg)})
      _ -> :ok
    end
  end

  @cg "\u0007"
  @valid_chan ~r"^[#|&][^#{@cg}, ]+$"

  defp check_chan_name({:ok, {chan, agent}}) do
    case Regex.match?(@valid_chan, chan) do
      true -> {:ok, {chan, agent}}
      false -> {:err, Response.Err.e403(chan)}
    end
  end

  defp check_in_chan({:ok, {chan, agent}}) do
    %{:user => user} = Agent.get(agent, fn map -> map end)
    case Enum.member?(user.channels, chan) do
      true -> :ok
      false -> {:ok, {chan, agent}}
    end
  end

  # TODO: ALL OF THESE CHECKS
  defp check_invited({:ok, {chan, agent}}) do
    {:ok, {chan, agent}}
  end

  defp check_banned({:ok, {chan, agent}}) do
    {:ok, {chan, agent}}
  end

  defp check_key({:ok, {chan, agent}}) do
    {:ok, {chan, agent}}
  end

  defp check_limit({:ok, {chan, agent}}) do
    {:ok, {chan, agent}}
  end

  defp register_client({:ok, {chan, agent}}) do
    %{:user => user, :interface => interface} = Agent.get(agent, fn map -> map end)

    nuser = %{user| channels: user.channels ++ [chan]}
    Agent.update(agent, fn map -> Dict.put(map, :user, nuser) end)

    prefix = "#{user.nick}!#{user.user}@#{user.rdns}"
    joinmsg = %Message{prefix: prefix, command: "JOIN", trailing: chan}
    GenServer.call ExIRCd.SuperServer.Server, {:join_chan, {user.nick, interface}, chan}
    GenServer.call ExIRCd.SuperServer.Server, {:send_to_chan, chan, joinmsg, ""}
    {:ok, {chan, agent}}
  end

  defp reply_topic({:ok, {chan, agent}}) do
    #TODO Figure out Ecto
    {:ok, {chan, agent}}
  end

  defp reply_names({:ok, {chan, agent}}) do
    %{:handler => handler, :user => user} = Agent.get(agent, fn map -> map end)
    
    #Aggregate all nicks in the chan, then split them into groups of 15 and send
    # TODO use prefixes
    [{^chan, channel}] = :ets.lookup(:channels, chan)
    clients = :ets.foldl(fn {nick, pid}, users ->
      [{nick,pid}|users]
    end, [], channel)
    name_lists = Enum.reduce clients, [[]], &split_names/2

    for name_list <- name_lists, do: send_name_repl(name_list, chan, user.nick, handler)

    name_end_msg = Response.Repl.r366(chan)
    |> MessageParser.parse_message_to_raw
    GenServer.call(handler, {:send, name_end_msg})

    {:ok, nil}
  end

  defp split_names({nick, pid}, [part|rest]) do
    case length(part) do
      15 -> [[nick]|[part|rest]]
      _ -> [[nick|part]|rest]
    end
  end

  defp send_name_repl(name_list, chan, user_nick, handler) do
    names = Enum.reduce name_list, "", fn nick, acc -> "#{nick} #{acc}" end
    msg = Response.Repl.r353(user_nick, "=", chan, names)
    |> MessageParser.parse_message_to_raw

    GenServer.call(handler, {:send, msg})
  end
end
