defmodule ExIRCd.Client.Command do
  @moduledoc """
  A module which deals with client connection initialization.
  A InitModule may perform tasks like checking for passwords,
  displaying the welcome message, and moer.
  """

  @doc """
  Callback for an init module that takes a message, an agent, and
  returns :ok on success.
  """
  @callback check(%ExIRCd.Client.Message{}, Agent.t) :: true | false

  @doc """
  Callback for parsing a message once it's been validated.
  """
  @callback parse(%ExIRCd.Client.Message{}, Agent.t) :: {:ok, any} | {:error, %ExIRCd.Client.Message{}} | {:failed, any}
end
