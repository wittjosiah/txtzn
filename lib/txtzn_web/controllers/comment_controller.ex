defmodule TxtznWeb.CommentController do
  use TxtznWeb, :controller

  alias CtznClient.{Session, Table}
  alias Plug.Conn

  require Logger

  def comment(%Conn{} = conn, %{"comment" => form}) do
    client_id = get_session(conn, :ctzn_client_id)
    %Session{user_id: user_id} = session = get_session(conn, :ctzn_session)

    community =
      with true <- is_binary(form["community"]),
           [community_id, community_url] <- String.split(form["community"], "<>") do
        %{dbUrl: community_url, user_id: community_id}
      else
        _ -> nil
      end

    [root_author, root_url] = String.split(form["root"], "<>")
    root_key = root_url |> String.split("/") |> List.last()
    root = %{authorId: root_author, dbUrl: root_url}
    reply = %{root: root}

    reply =
      with parent when is_binary(parent) <- form["parent"],
           [parent_author, parent_url] <- String.split(parent, "<>") do
        Map.put(reply, :parent, %{authorId: parent_author, dbUrl: parent_url})
      else
        _ -> reply
      end

    value = %{reply: reply, text: form["text"]}
    value = if community, do: Map.put(value, :community, community), else: value

    conn =
      with {:ok, ws} <- lookup_or_start_ws(client_id, session),
           {:ok, %{}} <- Table.create(ws, user_id, "ctzn.network/comment", value) do
        put_flash(conn, :info, "Created comment")
      else
        {:error, error} ->
          metadata = [error: inspect(error), user_id: user_id]
          Logger.error("Failed to create comment", metadata)
          put_flash(conn, :error, "Failed to comment")
      end

    redirect(conn, to: Routes.post_path(conn, :index, root_author, root_key))
  end
end
