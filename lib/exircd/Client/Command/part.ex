defmodule ExIRCd.Client.Command.Part do
  @behaviour ExIRCd.Client.Command
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.Response, as: Response
  alias ExIRCd.Client.MessageParser, as: MessageParser
  @moduledoc """
  Parses out the PART message.
  """

  def check(%Message{command: command, args: _arg_list, trailing: _trailing}, _agent) do
    command == "PART"
  end

  def parse(message, agent) do
    require Pipe

    %{:user => user} = Agent.get(agent, fn map -> map end)

    Pipe.pipe_matching {:ok, _},
    {:ok, {message, user}}
    |> check_registration
    |> check_args
    |> part_chans(agent)
  end

  defp check_registration({:ok, {message, user}}) do
    case user.registered do
      true ->
        {:ok, message}
      false ->
        {:error, Response.Err.e451}
    end
  end

  defp check_args({:ok, %Message{args: arg_list, trailing: trailing}}) do
    case arg_list do
      [] -> {:error, Response.Err.e461("Need more parameters")}
      [chans] -> {:ok, {String.split(chans, ","), trailing}}
    end
  end

  defp part_chans({:ok, {chans, part_msg}}, agent) do
    for chan <- chans, do: part_chan(chan, agent, part_msg)
    {:ok, nil}
  end

  defp part_chan(chan, agent, part_msg) do
    require Pipe

    res = Pipe.pipe_matching {:ok, _},
    {:ok, {chan, agent}}
    |> check_chan_name
    |> check_in_chan
    |> leave_chan(part_msg)

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
      true -> {:ok, {chan, agent}}
      false -> {:err, Response.Err.e442(chan)}
    end
  end

  defp leave_chan({:ok, {chan, agent}}, msg) do
    %{:user => user, :interface => interface} = Agent.get(agent, fn map -> map end)

    nuser = %{user| channels: user.channels -- [chan]}
    Agent.update(agent, fn map -> Dict.put(map, :user, nuser) end)

    prefix = "#{user.nick}!#{user.user}@#{user.rdns}"
    partmsg = %Message{prefix: prefix, command: "PART", args: [chan], trailing: msg}
    GenServer.call ExIRCd.SuperServer.Server, {:send_to_chan, chan, partmsg, ""}
    GenServer.call ExIRCd.SuperServer.Server, {:leave_chan, {user.nick, interface}, chan}
    {:ok, nil}
  end
end
