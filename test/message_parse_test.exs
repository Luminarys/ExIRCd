defmodule MessageParseTest do
  use ExUnit.Case
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.ConnServer.User, as: User
  alias ExIRCd.Client.MessageParser, as: Parser

  test "parse raw" do
    user = %User{:user => "test", :nick => "test", :rdns => "localhost" }
    s = "USER test 8 * :test name\r\n"
    message = %Message{args: ["test", "8", "*"], trailing: "test name", command: "USER", prefix: "test!test@localhost"}
    {:ok, parsed} = Parser.parse_raw_to_message(s, user)
    assert parsed == message
  end

  test "parse message" do
    raw = ":ExIRCd@localhost NOTICE * test :*** Looking up your hostname...\r\n"
    message = %Message{args: ["*", "test"], trailing: "*** Looking up your hostname...", command: "NOTICE", prefix: "ExIRCd@localhost"}
    parsed = Parser.parse_message_to_raw(message)
    assert parsed == raw
  end
end
