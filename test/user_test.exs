defmodule UserCommandTest do
  use ExUnit.Case
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.ConnServer.User, as: User
  alias ExIRCd.Client.Command, as: Command
  alias ExIRCd.Client.Response, as: Response

  test "Already registered" do
    {:ok, agent} = Agent.start_link fn -> %{} end
    user = %User{:registered => true}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: ["test", "8", "*"], trailing: "test name", command: "USER"}
    assert {:error, Response.Err.e462("You may not reregister")} == Command.User.parse(message, agent)
  end

  test "Not enough args" do
    {:ok, agent} = Agent.start_link fn -> %{} end
    user = %User{}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: ["*"], trailing: "test name", command: "USER"}
    assert {:error, Response.Err.e461("Incorrect parameter number")} == Command.User.parse(message, agent)
  end

  test "No realname" do
    {:ok, agent} = Agent.start_link fn -> %{} end
    user = %User{}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: ["test", "8", "*"], trailing: "", command: "USER"}
    assert {:error, Response.Err.e461("Not enough parameters")} == Command.User.parse(message, agent)
  end

  test "Success" do
    username = "test"
    realname = "tester"
    {:ok, agent} = Agent.start_link fn -> %{} end
    user = %User{}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: [username, "8", "*"], trailing: realname, command: "USER"}
    assert {:ok, nil} == Command.User.parse(message, agent)

    %{:user => nuser} = Agent.get(agent, fn map -> map end)
    assert %User{user: username, name: realname, modes: [:i]} == nuser
  end
end
