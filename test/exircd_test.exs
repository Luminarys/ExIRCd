defmodule ExIRCdTest do
  use ExUnit.Case
  doctest ExIRCd

  test "the truth" do
    assert 1 + 1 == 2
  end

  # @tag timeout: 1000000
  # test "stress" do
  #   :observer.start
  #   l = for _n <- 1..50000, do: spawn(fn -> connect(self()) end)
  #   :timer.sleep(200000)
  # end

  # def connect(pid) do
  #   time = :random.uniform(10)
  #   :timer.sleep(50 * time)
  #    socket = Socket.connect! "tcp://localhost:8080"
  #    socket |> Socket.Stream.send! "USER guest 8 * :Ronnie Reagan\r\n"
  #    socket |> Socket.Stream.send! "NICK lol\r\n"
  #    poll(socket, 10)
  # end


  # def poll(socket, 0), do: Socket.close! socket
  # def poll(socket, num) do
  #   time = :random.uniform(100)
  #   :timer.sleep(20 * time)
  #   try do
  #     socket |> Socket.Stream.send! "TEST ARGS TEST\r\n"
  #     poll(socket, num-1)
  #   rescue
  #   _ in Socket.Error -> 
  #     poll(socket, num-1)
  #   end
  # end
end
