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

    %{:user => user} = Agent.get(agent, fn map -> map end)
    Pipe.pipe_matching {:ok, _},
    {:ok, {message, user}}
    |> check_args
    |> check_restriction
    |> check_valid
    |> check_available
    |> update_registration
    |> set_nick(agent)
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
    %{:interface => interface} = Agent.get(agent, fn map -> map end)
    GenServer.call ExIRCd.SuperServer.Server, {:add_client, nick, interface}
    {:ok, nil}
  end
end
