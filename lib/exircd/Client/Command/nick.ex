defmodule ExIRCd.Client.Command.Nick do
  @behaviour ExIRCd.Client.Command
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.Response, as: Response
  @moduledoc """
  Parses out the NICK message.
  """

  def check(%Message{command: command, args: _arg_list, trailing: _trailing}, _agent) do
    command == "NICK"
  end

  def parse(message, agent) do
    require Pipe

    %{:user => user, :interface => interface} = Agent.get(agent, fn map -> map end)
    Pipe.pipe_matching {:ok, _},
    {:ok, {message, user}}
    |> check_args
    |> check_restriction
    |> check_valid
    |> check_available
    |> update_registration
    |> set_nick(agent)
    |> broadcast_change(message, interface)
  end

  defp check_args({:ok, {%Message{args: arg_list, trailing: _trailing}, user}}) do
    case arg_list do
      [nick|_rest] ->
        {:ok, {nick, user}}
      _ ->
        {:error, Response.Err.e431}
    end
  end

  defp check_restriction({:ok, {nick, user}}) do
    case Enum.member?(user.modes, :r) do
      true ->
        {:error, Response.Err.e484}
      false ->
        {:ok, {nick, user}}
    end
  end

  defp check_valid({:ok, {nick, user}}) do
    acceptable_nicks = ~r"([a-zA-Z]|_|\\|\[|\]|\{|\}|\^|\`|\|)([a-zA-Z0-9]|_|-|\\|\[|\]|\{|\}|\^|\`|\|)*"
    case Regex.run acceptable_nicks, nick do
      [^nick|_othermatches] ->
        {:ok, {nick, user}}
      _ ->
        {:error, Response.Err.e432(nick)}
    end
  end

  defp check_available({:ok, {nick, user}}) do
    # TODO: Actually check all nicks in use.
    case GenServer.call ExIRCd.SuperServer.Server, {:nick_available?, nick} do
      true ->
        {:ok, {nick, user}}
      false ->
        {:error, Response.Err.e433(nick)}
    end
  end

  defp update_registration({:ok, {nick, user}}) do
    case user.user do
      "" -> {:ok, {nick, user}}
      _ -> {:ok, {nick, %{user| registered: true}}}
    end
  end

  defp set_nick({:ok, {nick, user}}, agent) do
    nuser = %{user| nick: nick}
    Agent.update(agent, fn map -> Dict.put(map, :user, nuser) end)
    # The ordering here is weird, so we just send the old user w/old nick
    {:ok, {nick, user}}
  end

  defp broadcast_change({:ok, {nick, user}}, message, interface) do
    # Check if the nick is being set newly, if not do a broadcast
    case GenServer.call ExIRCd.SuperServer.Server, {:nick_available?, user.nick} do
      true ->
        GenServer.call ExIRCd.SuperServer.Server, {:add_client, nick, interface}
        {:ok, nil}
      false ->
        GenServer.call ExIRCd.SuperServer.Server, {:change_nick, user.nick, nick}
        for chan <- user.channels,
        do: GenServer.call ExIRCd.SuperServer.Server, {:send_to_chan, chan, message, ""}
        {:ok, nil}
    end
  end
end
