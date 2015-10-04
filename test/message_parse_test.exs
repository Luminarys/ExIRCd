defmodule MessageParseTest do
  use ExUnit.Case
  alias ExIRCd.Client.Message, as: Message
  alias ExIRCd.Client.MessageParser, as: Parser

  test "parse raw" do
    s = ":prefix@test NOTICE * test :*** Looking up your hostname...\r\n"
    message = %Message{args: ["*", "test"], trailing: "*** Looking up your hostname...", command: "NOTICE", prefix: ":prefix@test"}
    {:ok, parsed} = Parser.parse_raw_to_message(s)
    assert parsed == message
  end

  test "parse message" do
    raw = ":ExIRCd@localhost NOTICE * test :*** Looking up your hostname...\r\n"
    message = %Message{args: ["*", "test"], trailing: "*** Looking up your hostname...", command: "NOTICE", prefix: ":prefix@test"}
    parsed = Parser.parse_message_to_raw(message)
    assert parsed == raw
  end
end
