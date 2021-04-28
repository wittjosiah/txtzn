defmodule Txtzn.CtznHelpers do
  @moduledoc """
  Helper modules for working with `CtznClient`.

  Maybe should be rolled into the client?
  """

  alias CtznClient.{Session, Supervisor}

  def lookup_or_start_ws(client_id, %Session{} = session) do
    [_, host] = String.split(session.user_id, "@")
    lookup_or_start_ws(client_id, host)
  end

  def lookup_or_start_ws(client_id, host) do
    case Registry.lookup(Registry.CtznClient, client_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> Supervisor.start_child(client_id: client_id, host: host)
    end
  end
end
