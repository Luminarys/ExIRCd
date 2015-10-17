defmodule ExIRCd.SuperServer.Server do
  @moduledoc """
  Performs server level tasks of delivering messages to connections,
  and updates to the SQL server. All messages will pass through this
  if they want to either alter the server state or be sent to other
  clients.
  """
  require Logger
  use GenServer
  
  @doc """
  Starts the super server with the given state
  and options, if they are passed
  """
  def start_link({clients, channels}, opts) do
    GenServer.start_link(__MODULE__, {clients, channels}, opts)
  end

  def init({clients, channels}) do
    {:ok, {clients, channels}}
  end

  @doc """
  Adds a registered connection to the clients table
  """
  def handle_call({:add_client, nick, pid}, _from, {clients, channels}) do
    :ets.insert(clients, {nick, pid})
    {:reply, :ok, {clients, channels}}
  end

  @doc """
  Removes a registered connection from the clients table
  """
  def handle_call({:remove_client, nick, chans}, _from, {clients, channels}) do
    :ets.delete(clients, nick)
    for chan <- chans, do: leave_chan(nick, chan, channels)
    {:reply, :ok, {clients, channels}}
  end

  @doc """
  Checks if a nick is currently in use.
  """
  def handle_call({:nick_available?, nick}, _from, {clients, channels}) do
    case :ets.lookup(clients, nick) do
      [{^nick, _pid}] ->
        {:reply, false, {clients, channels}}
      [] ->
        {:reply, true, {clients, channels}}
    end
  end

  @doc """
  Renames a client's nick to a new one, changing it in all chans..
  """
  def handle_call({:change_nick, old_nick, new_nick}, _from, {clients, channels}) do
    [{^old_nick, pid}] = :ets.lookup(clients, old_nick)
    :ets.insert(clients, {new_nick, pid})
    :ets.foldl(fn {_chan_name, chan}, _acc ->
      case :ets.lookup(chan, old_nick) do
        [{^old_nick, interface}] ->
          :ets.insert(chan, {new_nick, interface})
          :ets.delete(chan, old_nick)
        _ ->
          :ok
      end
    end, :ok, channels)
    :ets.delete(clients, old_nick)
    {:reply, :ok, {clients, channels}}
  end

  @doc """
  Adds a registered connection to a channel.
  """
  def handle_call({:join_chan, {nick, pid}, chan}, _from, {clients, channels}) do
    case :ets.lookup(channels, chan) do
      [{^chan, channel}] ->
        :ets.insert(channel, {nick, pid})
        {:reply, :ok, {clients, channels}}
      [] ->
        channel = :ets.new(:channel, [:set, :protected])
        :ets.insert(channel, {nick, pid})
        :ets.insert(channels, {chan, channel})
        {:reply, :new_chan, {clients, channels}}
    end
  end

  @doc """
  Removes a registered connection from a channel, cleaning up
  empty channels.
  """
  def handle_call({:leave_chan, nick, chan}, _from, {clients, channels}) do
    {:reply, leave_chan(nick, chan, channels), {clients, channels}}
  end

  @doc """
  Broadcasts a message to all clients in a channel.
  """
  def handle_call({:send_to_chan, chan, message, sender}, _from, {clients, channels}) do
    send_to_chan(chan, message, channels, sender)
    {:reply, :ok, {clients, channels}}
  end

  defp leave_chan(nick, chan, channels) do
    case :ets.lookup(channels, chan) do
      [{^chan, channel}] ->
        :ets.delete(channel, nick)
        case :ets.last(channel) do
          :"$end_of_table" ->
            :ets.delete(channels, chan)
            :ok
          _ ->
            :ok
        end
      [] ->
        :error
    end
  end

  defp send_to_chan(chan, message, channels, sender) do
    case :ets.lookup(channels, chan) do
      [{^chan, channel}] ->
        :ets.foldl(fn {nick, pid}, _acc ->
          if nick != sender do
            GenServer.cast(pid, {:super_server_msg, message})
          end
        end, :ok, channel)
        :ok
      [] -> :ok
    end
  end
end
