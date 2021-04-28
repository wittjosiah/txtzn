defmodule TxtznWeb.SessionController do
  use TxtznWeb, :controller

  alias CtznClient.{Accounts, Session}
  alias Plug.Conn

  def sign_in(%Conn{} = conn, %{"sign_in" => %{"user_id" => user_id, "password" => password}}) do
    [username, host] = String.split(user_id, "@")
    client_id = get_session(conn, :ctzn_client_id)
    login_params = %{username: username, password: password}

    with {:ok, pid} <- lookup_or_start_ws(client_id, host),
         {:ok, result} <- Accounts.login(pid, login_params),
         %Session{} = session <- Session.parse(result) do
      conn
      |> put_session(:ctzn_session, session)
      |> redirect(to: Routes.feed_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "Failed to login")
        |> redirect(to: Routes.session_path(conn, :index))
    end
  end
end
