defmodule ExIRCd.Client.Command.User do
  @behaviour ExIRCd.Client.Command
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.Response, as: Response
  @moduledoc """
  Parses out the USER message setting user, name, and modes accordingly.
  """

  def check(%Message{command: command, args: _arg_list, trailing: _trailing}, _agent) do
    command == "USER"
  end

  def parse(message, agent) do
    require Pipe
    # Example USER command USER [username] [0 - no bit| 6 - wallop|8 - invis|] * :[real name]
    %{:user => user} = Agent.get(agent, fn map -> map end)
    Pipe.pipe_matching {:ok, _},
    {:ok, {message, user}}
    |> check_registration
    |> check_args
    |> apply_mask
    |> update_registration
    |> update_user(agent)
  end

  defp check_registration({:ok, {message, user}}) do
    case user do
      %{registered: true} ->
        {:error, Response.Err.e462("You may not reregister")}
      %{registered: false} ->
        {:ok, {message, user}}
    end
  end

  defp check_args({:ok, {%Message{args: arg_list, trailing: trailing}, user}}) do
    case arg_list do
      [username, mask, _unused] ->
        case trailing do
          "" ->
            {:error, Response.Err.e461("Not enough parameters")}
          realname ->
            {:ok, {{mask, username, realname}, user}}
        end
      _ ->
        {:error, Response.Err.e461("Incorrect parameter number")}
    end
  end

  defp apply_mask({:ok, {{mask, username, realname}, user}}) do
    case mask do
      "6" ->
        modes = user.modes ++ [:w]
        {:ok, %{user| user: username, name: realname, modes: modes}}
      "8" ->
        modes = user.modes ++ [:i]
        {:ok, %{user| user: username, name: realname, modes: modes}}
      _ ->
        {:ok, %{user| user: username, name: realname}}
    end
  end

  defp update_registration({:ok, user}) do
    case user.nick do
      "" -> {:ok, user}
      _ -> {:ok, %{user| registered: true}}
    end
  end

  defp update_user({:ok, user}, agent) do
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    {:ok, nil}
  end
end
