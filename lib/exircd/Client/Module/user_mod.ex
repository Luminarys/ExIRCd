defmodule ExIRCd.Client.Command.User do
  @behaviour ExIRCd.Client.Command
  alias ExIRCd.Client.Message, as: Message
  @moduledoc """
  Parses out the USER message setting user, name, and modes accordingly.
  """

  def check(%Message{command: command, args: _arg_list, trailing: _trailing}, _agent) do
    {command == "USER", nil}
  end

  def parse(message, agent) do
    require Pipe
    # Example USER command USER [username] [0 - no bit| 6 - wallop|8 - invis|] * :[real name]
    %{:user => user} = Agent.get(agent, fn map -> map end)
    Pipe.pipe_matching {:ok, _},
    {:ok, {message, user}}
    |> check_registration
    |> validate_args
    |> apply_mask
    |> update_user(agent)
  end

  defp check_registration({:ok, {message, user}}) do
    case user do
      %{registered: true} ->
        {:error, %Message{prefix: "", command: "462", args: ["*","USER"], trailing: "You may not reregister"}}
      %{registered: false} ->
        {:ok, {message, user}}
    end
  end

  defp validate_args({:ok, {%Message{args: arg_list, trailing: trailing}, user}}) do
    case arg_list do
      [username, mask, _unused] ->
        case trailing do
          "" ->
            {:error, %Message{prefix: "", command: "461", args: ["*","USER"], trailing: "Not enough parameters"}}
          realname ->
            {:ok, {{mask, username, realname}, user}}
        end
      _ ->
        {:error, %Message{prefix: "", command: "461", args: ["*","USER"], trailing: "Incorrect parameter number"}}
    end
  end

  defp apply_mask({:ok, {{mask, username, realname}, user}}) do
    case mask do
      "6" ->
        {:ok, %{user| user: username, name: realname, modes: [:w]}}
      "8" ->
        {:ok, %{user| user: username, name: realname, modes: [:i]}}
      _ ->
        {:ok, %{user| user: username, name: realname}}
    end
  end

  defp update_user({:ok, user}, agent) do
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    {:ok, nil}
  end
end
