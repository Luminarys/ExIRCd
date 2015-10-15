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
  def handle_call({:remove_client, nick}, _from, {clients, channels}) do
    :ets.delete(clients, {clients, nick})
    {:reply, :ok, {clients, channels}}
  end

  def handle_call({:nick_available?, nick}, _from, {clients, channels}) do
    case :ets.lookup(clients, nick) do
      [{^nick, _pid}] ->
        {:reply, false, {clients, channels}}
      [] ->
        {:reply, true, {clients, channels}}
    end
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
    case :ets.lookup(channels, chan) do
      [{^chan, channel}] ->
        :ets.delete(channel, nick)
        case :ets.last(channel) do
          :"$end_of_table" ->
            :ets.delete(channels, chan)
            {:reply, :ok, {clients, channels}}
          _ ->
            {:reply, :ok, {clients, channels}}
        end
      [] ->
        {:reply, :error, {clients, channels}}
    end
  end
end
