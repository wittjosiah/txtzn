defmodule TxtznWeb.PostController do
  use TxtznWeb, :controller

  alias CtznClient.{Session, Table}
  alias Plug.Conn

  require Logger

  def post(%Conn{} = conn, %{"post" => form}) do
    client_id = get_session(conn, :ctzn_client_id)
    %Session{user_id: user_id} = session = get_session(conn, :ctzn_session)
    value = Map.put(form, "createdAt", DateTime.to_string(DateTime.utc_now()))

    conn =
      with {:ok, ws} <- lookup_or_start_ws(client_id, session),
           {:ok, %{"key" => _key, "url" => _url}} <-
             Table.create(ws, user_id, "ctzn.network/post", value) do
        put_flash(conn, :info, "Created post")
      else
        {:error, error} ->
          metadata = [error: inspect(error), user_id: user_id]
          Logger.error("Failed to create post (UserId=#{user_id})", metadata)
          put_flash(conn, :error, "Failed to post")
      end

    redirect(conn, to: Routes.feed_path(conn, :index))
  end
end
