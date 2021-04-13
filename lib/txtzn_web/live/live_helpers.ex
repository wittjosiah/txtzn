defmodule TxtznWeb.LiveHelpers do
  @moduledoc """
  Documentation for `TxtznWeb.LiveHelpers`
  """

  import Phoenix.LiveView

  alias CtznClient.{Session, Supervisor}
  alias Phoenix.LiveView.Socket
  alias TxtznWeb.Router.Helpers, as: Routes

  def assign_defaults(%Socket{} = socket, %{
        "ctzn_session" => %Session{user_id: user_id} = session,
        "ctzn_client_id" => client_id
      }) do
    [_, host] = String.split(user_id, "@")
    {:ok, pid} = lookup_or_start_ws(client_id, host)

    socket
    |> assign(:ctzn_session, session)
    |> assign(:ctzn_ws_pid, pid)
    |> assign(:client_id, client_id)
  end

  def assign_defaults(%Socket{} = socket, session) do
    IO.inspect(session, label: "HELPERS")
    {:ok, redirect(socket, to: Routes.session_path(socket, :index))}
  end

  defp lookup_or_start_ws(client_id, host) do
    case Registry.lookup(Registry.CtznClient, client_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> Supervisor.start_child(client_id: client_id, host: host)
    end
  end
end
