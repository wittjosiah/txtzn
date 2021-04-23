defmodule TxtznWeb.PostLive do
  use TxtznWeb, :live_view

  import TxtznWeb.LiveHelpers

  alias CtznClient.{Session, View, Table}
  alias Phoenix.LiveView.Socket
  alias TxtznWeb.Components.{CommentTree, Post}

  require Logger

  @impl true
  def handle_event("comment", %{"comment" => %{"text" => text}}, %Socket{} = socket) do
    %{ctzn_session: %Session{user_id: user_id}, ctzn_ws_pid: ws, post: post} = socket.assigns

    community =
      if community = get_in(post, ["value", "community"]),
        do: Map.take(community, ["dbUrl", "userId"])

    root = %{authorId: get_in(post, ["author", "userId"]), dbUrl: post["url"]}
    reply = %{root: root}
    value = %{reply: reply, text: text}
    value = if community, do: Map.put(value, :community, community), else: value

    case Table.create(ws, user_id, "ctzn.network/comment", value) do
      {:ok, %{"key" => _key, "url" => _url}} ->
        {:noreply, socket}

      {:error, error} ->
        metadata = [error: inspect(error), user_id: user_id]
        Logger.error("Failed to create comment", metadata)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_params(%{"key" => key, "user_id" => user_id}, _uri, %Socket{} = socket) do
    socket =
      socket
      |> assign_post(user_id, key)
      |> assign_thread()

    {:noreply, socket}
  end

  @impl true
  def mount(_params, session, %Socket{} = socket) do
    with %Socket{} = socket <- assign_defaults(socket, session) do
      {:ok, assign(socket, :page_title, "Post")}
    end
  end

  defp assign_post(%Socket{assigns: %{ctzn_ws_pid: ws}} = socket, user_id, key) do
    case View.get(ws, "ctzn.network/post-view", [user_id, key]) do
      {:ok, %{"author" => %{"displayName" => name}} = result} ->
        socket
        |> assign(:post, result)
        |> assign(:page_title, "Post by #{name}")

      {:error, error} ->
        metadata = [client_id: socket.assigns.client_id, error: inspect(error)]
        Logger.error("Failed to fetch post", metadata)
        put_flash(socket, :error, "Failed to fetch post")
    end
  end

  defp assign_thread(%Socket{assigns: %{ctzn_ws_pid: ws, post: %{"url" => url}}} = socket) do
    case View.get(ws, "ctzn.network/thread-view", [url]) do
      {:ok, %{"comments" => comments}} ->
        assign(socket, :comments, comments)

      {:error, error} ->
        metadata = [client_id: socket.assigns.client_id, error: inspect(error)]
        Logger.error("Failed to fetch thread", metadata)
        put_flash(socket, :error, "Failed to fetch thread")
    end
  end

  defp assign_thread(%Socket{} = socket), do: socket
end
