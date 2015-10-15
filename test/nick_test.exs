defmodule NickCommandTest do
  use ExUnit.Case
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.ConnServer.User, as: User
  alias ExIRCd.Client.Command, as: Command
  alias ExIRCd.Client.Response, as: Response

  test "No nick given" do
    {:ok, agent} = Agent.start_link fn -> %{} end
    user = %User{}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: [], command: "NICK"}
    assert {:error, Response.Err.e431} == Command.Nick.parse(message, agent)
  end

  test "Restricted user" do
    {:ok, agent} = Agent.start_link fn -> %{:interface => self()} end
    user = %User{:modes => [:r]}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: ["test"], command: "NICK"}
    assert {:error, Response.Err.e484} == Command.Nick.parse(message, agent)
  end

  test "Invalid nick" do
    nick = "@#$*#$(&@(#&$"
    {:ok, agent} = Agent.start_link fn -> %{:interface => self()} end
    user = %User{}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: [nick], command: "NICK"}
    assert {:error, Response.Err.e432(nick)} == Command.Nick.parse(message, agent)
  end

  test "Nick Taken" do
    # TODO: Write proper test/mock for this
    assert 1 == 1
  end

  test "Success" do
    nick = "test"
    s = self()
    {:ok, agent} = Agent.start_link fn -> %{:interface => s} end
    user = %User{}
    Agent.update(agent, fn map -> Dict.put(map, :user, user) end)
    message = %Message{args: [nick], command: "NICK"}
    assert {:ok, nil} == Command.Nick.parse(message, agent)

    %{:user => nuser} = Agent.get(agent, fn map -> map end)
    assert %User{nick: nick} == nuser

    assert [{nick, s}] == :ets.lookup(:clients, nick)
  end
end
