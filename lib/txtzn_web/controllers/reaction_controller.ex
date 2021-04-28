defmodule TxtznWeb.ReactionController do
  use TxtznWeb, :controller

  alias CtznClient.{Session, Table}
  alias Plug.Conn

  require Logger

  def react(%Conn{} = conn, %{"reaction" => form}) do
    client_id = get_session(conn, :ctzn_client_id)
    %Session{user_id: user_id} = session = get_session(conn, :ctzn_session)
    key = form["post_url"] |> String.split("/") |> List.last()

    value = %{
      reaction: form["reaction"],
      subject: %{dbUrl: form["post_url"], authorId: form["post_author"]}
    }

    conn =
      with {:ok, ws} <- lookup_or_start_ws(client_id, session),
           {:ok, _} <- Table.create(ws, user_id, "ctzn.network/reaction", value) do
        put_flash(conn, :info, "Added reaction")
      else
        {:error, error} ->
          metadata = [error: inspect(error), user_id: user_id]
          Logger.error("Failed to react to post (#{key})", metadata)
          put_flash(conn, :error, "Failed to add reaction")
      end

    redirect(conn, to: Routes.post_path(conn, :index, form["post_author"], key))
  end
end
